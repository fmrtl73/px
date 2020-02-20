# Deploy Postgres and Insert Data
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
# Create Namespace Backup
### Create backup credentials and location
Modify the postgres-backup-location.yaml file to point to an S3 compatible objectstore with the correct credentials. See [CRD Docs](https://docs.portworx.com/portworx-install-with-kubernetes/storage-operations/stateful-applications/crd-reference/) for more details on the different values you should use.
```
kubectl apply -f postgres-backup-location.yaml
```
### Take a backup of the postgres namespace
Create a on-demand application backup using the ApplicationBackup CRD
```
kubectl apply -f postgres-backup.yaml
```

# Restore Namespace
### Delete the postgres namespace and restore it from your backup
Delete the namespace
```
kubectl delete ns postgres
```
Create the namespace again and create the backup location as well
```
kubectl create namespace postgres
kubectl create -f postgres-backup-location.yaml
```
Restore the namespace from the backup using the ApplicationRestore CRD. When you create the backup location stork will find your backup and populate it in your namespace. Here we're going to use sed to replace the backup name in the BackupRestore object to point to our backup.
```
backup=`kubectl get applicationbackups -n postgres | grep postgres-backup | awk '{print $1}'`
sed "s/BACKUP_NAME/$backup/g" postgres-restore.yaml > postgres-restore-backup.yaml
kubectl apply -f postgres-restore-backup.yaml 
```
Check the status of the restore operation
```
kubectl describe applicationrestore -n postgres
kubectl get all -n postgres
```
### Verify the data has been recovered
```
POD=`kubectl get po -n postgres | grep -v NAME | awk '{print $1}'`
kubectl exec -it $POD -n postgres bash
psql pxdemo
select count(*) from pgbench_accounts;
\q
exit
```
