This project is meant to help in running a set of benchmarks, defined in the config map in standard fio format, agains one or more storage classes. The run.sh script uses the fio-job.yaml file as a template and generates a job for each storage class that runs in sequential order. 

### Setup

Before you start, if you want to test secure storage class performance make sure you have a functioning Portworx cluster and configure it for encryption:
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

### Running the benchmark

For each storage class the script will create a PVC, and fio container as a job. The fio container uses the fiojobs.fio file contained in the configmap.yaml file.

You can run all tests using the storage classes which starts with fio:
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

### Processing the JSON Results

This requires that you install jq.

The results of the benchmark are available in the job's container logs and will be outputed in JSON format. To convert the job's results to CSV you can use the create-csv.sh script:

```
./create-csv.sh <storage-class-name>
```

This will create a CSV with ephemeral results first followed by portworx results.


