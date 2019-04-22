delete(){
    kubectl delete -f $1/psql.yaml
    kubectl delete -f $1/pgbench-init.yaml
    kubectl delete -f $1/pgbench-run.yaml
    rm -rf $sc
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
    delete $sc
  done
  exit 0
fi
delete $1
