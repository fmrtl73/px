There are four tests defined (high, high-compressed, medium, medium-compressed) defined to test performance on two different storage pools (high,medium) with and without compression. It deploys the database and benchmark jobs for each in the portworx namespace.

Before you start, make sure you have a functioning Portworx cluster and configure it for encryption:
```
kubectl -n portworx create secret generic px-vol-encryption \
  --from-literal=cluster-wide-secret-key=Il0v3Portw0rX
PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets set-cluster-key \
  --secret cluster-wide-secret-key
```
You should create the storage classes before running the tests:

```
kubectl create -f storage-classes.yaml
```

For each test we will create a storage class with specific storage properties and then use it to create a PVC, and fio container as a job. There are two jobs, a fio-write job and a fio-read job that the run.sh script runs in that order.

You can run all tests using the fio prefixed storage classes:
```
./run.sh --all fio
```

The files are created in a directory with the storage class name. You can delete all resources created by running the following script:
```
./clean.sh --all fio 
```

You can run and clean individual storage class using the following commands:
```
./run.sh <storage-class-name>
./clean.sh <storage-class-name>
```
