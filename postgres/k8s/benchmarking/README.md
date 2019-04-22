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

You can run all tests using the `run-all.sh` script then delete all the resources using the `clean-all.sh` script. You can also run individual test by following the below instructions.

## High Speed Device, no encryption
Start the database:
```
kubectl create -f psql-high-no-encyption.yaml
```
When the database is running and ready you can launch a kubernetes job to initialize the database with 5 million rows of data (800MB):
```
kubectl create -f pgbench-init-high-no-encyption.yaml
````
Once the job completes successfully you can launch the kubernetes job to do the actual benchmark:
```
kubectl create -f pgbench-run-high-no-encyption.yaml
```

## High Speed Device
Start the database:
```
kubectl create -f psql-high.yaml
```
When the database is running and ready you can launch a kubernetes job to initialize the database with 5 million rows of data (800MB):
```
kubectl create -f pgbench-init-high.yaml
````
Once the job completes successfully you can launch the kubernetes job to do the actual benchmark:
```
kubectl create -f pgbench-run-high.yaml
```

## High Speed Device with compression
Start the database:
```
kubectl create -f psql-high-compressed.yaml
```
When the database is running and ready you can launch a kubernetes job to initialize the database with 5 million rows of data (800MB):
```
kubectl create -f pgbench-init-high-compressed.yaml
````
Once the job completes successfully you can launch the kubernetes job to do the actual benchmark:
```
kubectl create -f pgbench-run-high-compressed.yaml
```

## Medium Speed Device
Start the database:
```
kubectl create -f psql-medium.yaml
```
When the database is running and ready you can launch a kubernetes job to initialize the database with 5 million rows of data (800MB):
```
kubectl create -f pgbench-init-medium.yaml
````
Once the job completes successfully you can launch the kubernetes job to do the actual benchmark:
```
kubectl create -f pgbench-run-medium.yaml
```

## Medium Speed Device with compression
Start the database:
```
kubectl create -f psql-medium-compressed.yaml
```
When the database is running and ready you can launch a kubernetes job to initialize the database with 5 million rows of data (800MB):
```
kubectl create -f pgbench-init-medium-compressed.yaml
````
Once the job completes successfully you can launch the kubernetes job to do the actual benchmark:
```
kubectl create -f pgbench-run-medium-compressed.yaml
```

## Getting Benchmark Results
Once you have run all three commands you will be able to inspect the results. For example, with the medium test you will get the following:
```
kubectl get po -n portworx
NAME                                         READY   STATUS      RESTARTS   AGE
pgbench-init-medium-gqdw7                    0/1     Completed   0          7m16s
pgbench-run-medium-2tjwx                     0/1     Completed   0          6m7s
postgres-medium-5f7548dd6b-x2q7g             1/1     Running     0          8m4s
postgres-medium-compressed-7dc7cf6b8-4rksn   1/1     Running     0          15m

kubectl logs -n portworx pgbench-run-medium-2tjwx
starting vacuum...end.
transaction type: TPC-B (sort of)
scaling factor: 50
query mode: simple
number of clients: 10
number of threads: 2
number of transactions per client: 10000
number of transactions actually processed: 100000/100000
latency average: 12.587 ms
tps = 794.467449 (including connections establishing)
tps = 794.486714 (excluding connections establishing)
```
