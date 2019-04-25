#!/usr/bin/env bash

bench(){
  sc=$1
  mkdir $sc
  cp psql-template.yaml $sc/psql.yaml
  cp pgbench-init-template.yaml $sc/pgbench-init.yaml
  cp pgbench-run-template.yaml $sc/pgbench-run.yaml
  svcname=`echo $sc | awk '{ print toupper($0) }' | sed 's/-/_/g'`
  svcname=`echo $svcname`_SVC
  sed -i "s/SC_NAME/$sc/g" $sc/*.yaml
  sed -i "s/SVC_NAME/$svcname/g" $sc/*.yaml

  echo "##### Deploying psql test for storage class $sc"
  kubectl apply -f $sc/psql.yaml | awk '{print " # " $0}'
  echo " # Waiting for $podname pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $sc-app | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  kubectl create -f $sc/pgbench-init.yaml | awk '{print " # " $0}'
  echo " # Waiting for pgbench init pod to be ready, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep pgbench-init-$sc | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo " # Waiting for init pod to complete, will timeout after 5 minutes"
  kubectl -n portworx wait --for=condition=complete job/pgbench-init-$sc --timeout 5m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  kubectl create -f $sc/pgbench-run.yaml | awk '{print " # " $0}'
  echo " # Waiting for pgbench-run pod to be ready, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep pgbench-run-$sc | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo " # Results for storage class: $sc "
  kubectl -n portworx logs -f $pod | awk '{print "     " $0}'
  echo "        "
}
display_usage(){
  echo "This script requires parameters to run"
  echo "- to benchmark a storage class:"
  echo "     ./run.sh <storage-class-name>"
  echo "- to benchmark all storage classes with a given prefix: "
  echo "     ./run.sh --all <storage-class-prefix>"
}
sc=$1   # first command line argument
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi
if [ $1 == '--all' ]; then
  if [ $# -ne 2 ]; then
    display_usage
    exit 1
  fi
  for sc in $(kubectl get sc | grep $2 | awk '{print $1}')
  do
    bench $sc
  done
  exit 0
fi
bench $sc
