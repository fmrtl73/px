### Create source target deployment 

On the source cluster deploy the storage-class, pvc, and webapp using the yaml files in this repo.
```
kubectl create -f px-shared-sc.yaml
kubectl create -f px-shared-pvc.yaml
kubectl create -f webapp.yaml
```

### Create a config map in the source cluster

```
kubectl create cm readonly --from-literal deploy=webapp --from-literal svc=bapp-svc --from-literal replicas=3
```

### Create the Migration Schedule 

First, make sure you have the `remotecluster-2` cluster pair object in your source cluster and that it is pointing at your target cluster.

### Run the deploy-readonly.sh script in the target cluster

```
bash deploy-readonly.sh
```

### What you should see
Every 10 seconds the script will look for the config map object which the migration will create.

When it finds it, it will create a snapshot of the PVC referenced by the webapp deployment and clone this snapshot. 

It will then create a webapp-ro deployment and webapp-ro-svc service using that pvc clone. 

It will then delete the config map object and go into a loop until the migration creates it again.

When this happens it will again snapshot the pvc, create a clone, and this time it will do a rolling update of the webapp-ro deployment using the new pvc clone.

It will then cleanup the old snapshot and clone objects as well as the config map and start looping again.
