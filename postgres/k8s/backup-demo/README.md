### Create Namespace
```
kubectl create namespace postgres
```
### Deploy Postgres
```
kubectl apply -f postgres.yaml
```
### Insert some data
Exec into the Postgres POD
```
POD=`kubectl get po -n postgres | grep -v NAME | awk '{print $1}'`
kubectl exec -it $POD -n postgres bash
```
Start a psql session
```
psql
```
Create pxdemo database, list it to confirm it was created, and quit psql
```
create database pxdemo;
\l
\q
```
Create 800 MB of data using pgbench utility
```
pgbench -i -s 50 pxdemo
```
Verify the data has been inserted
```
psql pxdemo
select count(*) from pgbench_accounts;
\q
exit
```
### Create backup credentials and location
Modify the postgres-backup-location.yaml file to point to an S3 compatible objectstore with the correct credentials.
```
kubectl apply -f postgres-backup-location.yaml
```
### Take a backup of the postgres namespace
Create a on-demand application backup using the ApplicationBackup CRD
```
kubectl apply -f postgres-backup.yaml
```
### Delete the postgres namespace and restore it from your backup
Delete the namespace
```
kubectl delete ns postgres
```
Restore the namespace from the backup using the ApplicationRestore CRD
```
kubectl apply -f postgres-restore.yaml 
```
### Verify the data has been recovered
```
POD=`kubectl get po -n postgres | grep -v NAME | awk '{print $1}'`
kubectl exec -it $POD -n postgres
psql pxdemo
select count(*) from pgbench_accounts;
\q
exit
```
