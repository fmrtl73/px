kubectl delete -f apache-nifi/deployment/ 
rm -r apache-nifi/deployment
kubectl delete -f zookeeper/deployment/ 
rm -r zookeeper/deployment
kubectl delete -f portworx-sc.yaml
