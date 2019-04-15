The commands deploys the four storage classes, pvcs, services, and PostgreSQL deployments with io priority high and medium and compression set to true and false:

```kubectl create -f psql-high.yaml
kubectl create -f psql-high-compressed.yaml
kubectl create -f psql-medium.yaml
kubectl create -f psql-medium-compressed.yaml
```

With those running you can then run the following commands to deploy and run the benchmark init command `-i -s 50 ` using a kubernetes job:

```
kubectl create -f pgbench-init-high.yaml
kubectl create -f pgbench-init-high-compressed.yaml
kubectl create -f pgbench-init-medium.yaml
kubectl create -f pgbench-init-medium-compressed.yaml
```

And finally these commands will run the benchmark `pgbench -c 10 -j 2 -t 10000`:

```
kubectl create -f pgbench-run-high.yaml
kubectl create -f pgbench-run-high-compressed.yaml
kubectl create -f pgbench-run-medium.yaml
kubectl create -f pgbench-run-medium-compressed.yaml
```

