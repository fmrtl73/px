This is to test concurrent fio jobs running on a set of nodes. The instructions below will guide you through running 10 jobs, notice that stork is set as the scheduler in the job to make sure that data locality provides better results. It uses the fmrtl73/dbench:0.12 docker image which is built from the docker/ folder. 

The fio tests are all configured in docker/docker-entrypoint.sh and run using a job defined in dbench.yaml and which uses the above mentioned container as well as an init container which lays out a 4GB fiotest file so that the job measures IOPS on existing data. 

### Create the storageclass and shared volume to sync all fio runs
The init.yaml file will create a px-dbench-sc storage class as well as a shared volume to hold a timestamp which will ensure all jobs start simultaneously. You can change the storageclass to test different configurations.
```
kubectl create -f init.yaml
```

### Launch 10 jobs with 10 PVCs
The dbench.yaml file is a template for the jobs, run this command to launch 10 jobs.
```
for i in 1 2 3 4 5 6 7 8 9 10; do sed "s/JOB_NAME/dbench-$i/g" dbench.yaml | kubectl apply -f -;  done
```
### Wait for all 10 jobs to complete
You should see that the jobs are well spread accross your nodes.
```
kubectl get po -o wide -w
```

### Summarize the IOPS results
```
for i in 1 2 3 4 5 6 7 8 9 10 ; do echo ++++++++++++ ; kubectl get po | grep dbench-$i- | awk '{print $1}'| xargs kubectl logs | grep IOPS= ;  done
```

### Cleanup
```
kubectl delete pvc dbench-sync
for i in 1 2 3 4 5 6 7 8 9 10; do kubectl delete job dbench-$i ; kubectl delete pvc dbench-$i; done
```
