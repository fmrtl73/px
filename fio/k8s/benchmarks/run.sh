#!/usr/bin/env bash
run_job(){
  name=$1
  sc=$2
  size=`grep "\-\-size" $name.yaml | cut -d'=' -f 2 | cut -d'"' -f 1`
  echo " # This test will write $size of data"
  kubectl apply -f $sc/$name.yaml | awk '{print " # " $0}'
  echo " # Waiting for pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $name-$sc | awk '{print $1}'`
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
  cp fio-read.yaml $sc/fio-read.yaml
  cp fio-write.yaml $sc/fio-write.yaml
  cp fio-rand-read.yaml $sc/fio-rand-read.yaml
  cp fio-rand-write.yaml $sc/fio-rand-write.yaml
  sed -i "s/SC_NAME/$sc/g" $sc/*.yaml

  echo "##### Deploying fio sequential write test for storage class $sc #####"
  run_job "fio-write" $sc
  echo "##### Deploying fio sequential read test for storage class $sc #####"
  run_job "fio-read" $sc
  echo "##### Deploying fio random write test for storage class $sc #####"
  run_job "fio-rand-write" $sc
  echo "##### Deploying fio random read test for storage class $sc #####"
  run_job "fio-rand-read" $sc

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
