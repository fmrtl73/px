#!/usr/bin/env bash 

bench(){
  sc=$1
  mkdir $sc
  cp fio-read.yaml $sc/fio-read.yaml
  cp fio-write.yaml $sc/fio-write.yaml
  sed -i "s/SC_NAME/$sc/g" $sc/*.yaml
  
  echo "Deploying fio write test for storage class $sc"
  kubectl apply -f $sc/fio-write.yaml
  echo "Waiting for pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep fio-write-$sc | awk '{print $1}'`
  echo $pod
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "Pod ready, tailing logs"
  echo "########## $run results ###############"
  kubectl -n portworx logs -f $pod
  echo "########## $run results end ###############"
  
  echo "Deploying fio-read test for storage class $sc"
  kubectl create -f $sc/fio-read.yaml
  echo "waiting for pod to be ready, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep fio-read-$sc | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo "Pod ready, tailing logs"
  echo "########## $run results ###############"
  kubectl -n portworx logs -f $pod
  echo "########## $run results end ###############"
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

