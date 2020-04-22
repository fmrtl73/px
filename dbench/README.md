This is to test concurrent fio jobs running on a set of nodes. THe scenario below is to run 10 jobs, notice that stork is set as the scheduler in the job to make sure that data locality provides better results. It uses the fmrtl73/dbench:0.10 docker image which features this docker-entrypoint.sh file in this folder. 

The tests are run using a job defined in dbench.yaml and which uses the above mentioned container as well as an init container which lays out a 4GB fiotest file so that the job measures IOPS on existing data. 

### Create the storageclass
This storage class is a sharedv4 repl1 volume. You can change the storageclass to test different configurations.
```
kubectl create -f px-repl1-sc.yaml
```

### Launch 10 jobs with 10 PVCs
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
for i in 1 2 3 4 5 6 7 8 9 10; do kubectl delete job dbench-$i ; kubectl delete pvc dbench-$i  done
```
