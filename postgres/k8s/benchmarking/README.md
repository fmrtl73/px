
### Before you start
Make sure you have a functioning Portworx cluster and that it's configured for encryption. The ```run.sh``` script will check in the portworx namespace for a secret named ```px-vol encryption```, if it doesn't exist it will create it and set it as the cluster key in Portworx. If you have configured a different kms or key just create the px-vol-encryption secret:
```
kubectl -n portworx create secret generic px-vol-encryption \
  --from-literal=cluster-wide-secret-key=Il0v3Portw0rX
PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets set-cluster-key --secret cluster-wide-secret-key
```

### Running the tests
The ```run.sh``` script takes a storage-class name as it's input and then creates a PVC based from it, deploys an instance of Postgres based on the ```psql-template.yaml``` specification, and then runs both the init and run pgbench jobs defined in ```pgbench-init-template.yaml``` and ```pgbench-run-template.yaml``` specifications. To customize the benchmark you just need to create your own storage classes and edit the ```args: ["-c" ... ``` line of the init and run specs to change the pgbench parameters.

This repo comes with a set of storage classes you may want to benchmark, you can create them with kubectl:
```
kubectl create -f storage-classes.yaml
```

Run one benchmark, for example we'll run the repl1 high priority IO benchmark:
```
./run.sh psql-high-repl1
```  
Now run all benchmarks with storage class names starting in *psql*:
```
./run.sh --all psql
```

### Clean up after yourself
You can clean up k8s artifacts and volumes using the following commands:
```
./clean.sh psql-high-repl1
./clean.sh --all psql
```
