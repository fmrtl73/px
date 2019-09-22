kubectl create -f sc.yaml
kubectl apply -f amq.yaml
pod=`kubectl get po | grep amq | awk '{print $1}'`
kubectl -n portworx wait --for=condition=Ready po/$pod --timeout 2m | awk '{print " # " $0}'
if (( $? )); then
  echo "Failure" >&2
  exit 1
fi
kubectl cp util $pod:/tmp/utility
