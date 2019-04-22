There are four tests defined (high, high-compressed, medium, medium-compressed) defined to test performance on two different storage pools (high,medium) with and without compression. It deploys the database and benchmark jobs for each in the portworx namespace.

Before you start, make sure you have a functioning Portworx cluster and configure it for encryption:
```
kubectl -n portworx create secret generic px-vol-encryption \
  --from-literal=cluster-wide-secret-key=Il0v3Portw0rX
PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets set-cluster-key \
  --secret cluster-wide-secret-key
```
Also, you should set a password secret in the Portworx namespace:
```
echo -n mysql123 > password.txt
kubectl create secret generic postgres-pass --from-file=password.txt -n portworx
```

Finally, you should create the storage classes before running the tests:

```
kubectl create -f storage-classes.yaml
```

For each test we will create a storage class with specific storage properties and then use it to create a PVC, service, and PostgreSQL deployment. The benchmark init and run steps are then deployed as client pods as part of a batch job that runs only once. The logs for the pod will contain the benchmark results.

You can run all tests using the 
```
./run.sh --all psql
``` 

You can delete all resources created by running the following script:
```
./clean.sh --all psql
```

You can run and clean individual storage class using the following commands:
```
./run.sh <storage-class-name>
./clean.sh <storage-class-name>
``` 
