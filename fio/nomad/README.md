## How to run fio performance test on Nomad

Make sure you edit the files fio-write.nomad and fio-read.nomad to fit your environment:
- Update the `datacenter` field to one defined your Nomad environment
- You need to have access to internet so docker can pull the fio image. If you have a local docker repository you need to update the file accordingly
- The fio-write nomad job will create a Portworx volume named `test-volume` and write 10 GB of data for performance analysis
- The fio-read nomad job will read 10 GB of data from the `test-volume` volume. 
- You can update the volume name and size to fit your requirements, but make sure both job has same volume name and size.

First you have to run the following in one of your Nomad nodes:

```
nomad job run fio-write.nomad
```

This job will create a batch nomad job to write 10 GB of data to a Portworx volume and monitor performance.

You can see the volume size increase as the job writes more data using the command below:

```
watch pxctl volume inspect test-volume
```
Once the job completes you can check the logs to see fio output:

```
alloc=`nomad job status fio-write | grep complete | awk '{print $1}'`
nomad alloc logs $alloc
```
After that you can run the fio-read job
```
nomad job run fio-read.nomad
```
Now this job will read 10 GB of data from the Portworx volume created in the fio-write job and monitor performance.

Wait for the job to complete and check the logs.
The status should be `dead` when this batch job finishes. 
```
watch nomad job status fio-read
alloc=`nomad job status fio-read | grep complete | awk '{print $1}'`
nomad alloc logs $alloc
```


