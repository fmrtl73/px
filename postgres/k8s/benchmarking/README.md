There are four tests defined (high, high-compressed, medium, medium-compressed) defined to test performance on two different storage pools (high,medium) with and without compression.

For each test there is a storage class, PVC, service, and PostgreSQL deployment.

##High Speed Device
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

##High Speed Device with compression
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

##Medium Speed Device
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

##Medium Speed Device with compression
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
