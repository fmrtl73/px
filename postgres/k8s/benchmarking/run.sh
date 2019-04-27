#!/usr/bin/env bash
# bench method, takes a storage class as an argument and runs a psql benchmark against it
bench(){
  sc=$1
  mkdir $sc
  cp psql-template.yaml $sc/psql.yaml
  cp pgbench-init-template.yaml $sc/pgbench-init.yaml
  cp pgbench-run-template.yaml $sc/pgbench-run.yaml
  # the service name for storage-class is STORAGE_CLASS_SVC
  svcname=`echo $sc | awk '{ print toupper($0) }' | sed 's/-/_/g'`
  svcname=`echo $svcname`_SVC
  # replace SC_NAME and SVC_NAME in templates with $sc and $svcname
  sed -i "s/SC_NAME/$sc/g" $sc/*.yaml
  sed -i "s/SVC_NAME/$svcname/g" $sc/*.yaml
  # deploy the database
  echo "##### Deploying psql test for storage class $sc"
  kubectl apply -f $sc/psql.yaml | awk '{print " # " $0}'
  echo " # Waiting for $podname pod to start, will timeout after 2 minutes"
  pod=`kubectl get pod -n portworx | grep $sc-app | awk '{print $1}'`
  kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
  # deploy the pgbench init job and wait for it to complete
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
  # deploy the pgbench run job and tail it's logs
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
# display usage method
display_usage(){
  echo "This script requires parameters to run"
  echo "- to benchmark a storage class:"
  echo "     ./run.sh <storage-class-name>"
  echo "- to benchmark all storage classes with a given prefix: "
  echo "     ./run.sh --all <storage-class-prefix>"
}
# check if postgres password has been created, created it if it hasn't
kubectl -n portworx get secret postgres-pass &> /dev/null
if (( $? )); then
    echo -n mysql123 > password.txt
    kubectl create secret generic postgres-pass --from-file=password.txt -n portworx
    rm password.txt
fi
# check if cluster wide secret exists and set it on px if it doesn't
kubectl -n portworx get secret px-vol-encryption &> /dev/null
if (( $? )); then
    kubectl -n portworx create secret generic px-vol-encryption --from-literal=cluster-wide-secret-key=Il0v3Portw0rX &> /dev/null
    PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
    kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets set-cluster-key --secret cluster-wide-secret-key
fi
# check command line arguments
sc=$1  
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi
# for --all option check that there is a second argument
if [ $1 == '--all' ]; then
  if [ $# -ne 2 ]; then
    display_usage
    exit 1
  fi
  # get all storage classes and run benchmark on each
  for sc in $(kubectl get sc | grep $2 | awk '{print $1}')
  do
    bench $sc
  done
  exit 0
fi
# run the benchmark with the given storage class
bench $sc
