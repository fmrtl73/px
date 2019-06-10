
## Requirements

`./build_environment.sh small.yaml`

`kubectl create -f deployment/`

Test with
```
kubectl exec zk-0 cat /opt/zookeeper/conf/zoo.cfg --namespace=zk
kubectl exec zk-0 zkCli.sh create /hello tushar  --namespace=zk
kubectl exec zk-0 zkCli.sh get /hello  --namespace=zk
```
