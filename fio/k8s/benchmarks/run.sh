#!/usr/bin/env bash
run_job(){
  sc=$1
  kubectl apply -f configmap.yaml
  kubectl apply -f $sc/fio-job.yaml | awk '{print " # " $0}'
  echo " # Waiting for pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep fio-job-$sc | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  echo " # Results for sc:$sc job:$name: "
  kubectl -n portworx logs -f $pod | awk '{print "     " $0}'
  echo "                      "

}

bench(){
  sc=$1
  mkdir $sc
  cp fio-job.yaml $sc/fio-job.yaml
  sed -i "s/SC_NAME/$sc/g" $sc/*.yaml

  echo "##### Deploying fio sequential write test for storage class $sc #####"
  run_job $sc
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
