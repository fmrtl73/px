#!/usr/bin/env bash 
#set -x
for sc in $(kubectl get sc | grep -v psql | awk '{print $1}')
do
  podname=`echo $sc | sed 's/psql-/postgres-/g'`
  podname=`echo $podname | sed 's/compression/compressed/g'`
  filename=`echo $sc | sed 's/compression/compressed/g'`
  init=`echo $sc | sed 's/psql-/pgbench-init-/g'`
  run=`echo $sc | sed 's/psql-/pgbench-run-/g'`

  echo "Deploying psql for storage class $sc"
  kubectl apply -f $filename.yaml
  echo "Waiting for $podname pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $podname | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "Deploying pgbench init for storage class $sc"
  kubectl create -f $init.yaml
  echo "waiting for $init pod to be ready, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $init | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "waiting for $init to complete, will timeout after 5 minutes"
  kubectl -n portworx wait --for=condition=complete job/$init --timeout 5m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "Deploying pgbench run for storage class $sc"
  kubectl create -f $run.yaml
  echo "waiting for $run pod to be ready, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $run | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "Pod ready, tailing logs"
  echo "########## $run results ###############"
  kubectl -n portworx logs -f $pod
  echo "########## $run results end ###############"
done
