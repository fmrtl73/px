# MongoDB Operator Deployment with Portworx

## Create a namespace and deploy the operator

```
kubectl create ns mongodb
kubectl apply -f crds.yaml
kubectl apply -f mongodb-enterprise.yaml
```

### Check that it's up and running
```
kubectl get po -n mongodb -w
```

## Deploy the Ops Manager
Create the credentials
```
kubectl create secret generic admin-credentials \
  --from-literal=Username="admin" \
  --from-literal=Password="Password1#" \
  --from-literal=FirstName="francois" \
  --from-literal=LastName="martel"
```

Deploy a StorageClass and the MongoDB Ops Manager
```
kubectl create -f sc.yaml
kubectl apply -f opsmanager.yaml
```

Check that it is fully initialized
```
watch kubectl get po -n mongodb
```
Wait till the 3 opsmanager-db pods of the stateful set start and the opsmanager-0 pod is ready 1/1. The output of the get pod command should look something like this:
```
NAME                                          READY   STATUS    RESTARTS   AGE
mongodb-enterprise-operator-9b8c8c9c5-q2lqm   1/1     Running   0          4m1s
opsmanager-0                                  1/1     Running   0          46s
opsmanager-db-0                               1/1     Running   0          3m24s
opsmanager-db-1                               1/1     Running   0          2m30s
opsmanager-db-2                               1/1     Running   0          77s
```

## Login to the Ops Manager UI and finish the setup.

1. Open a browser to http://{worker-node-ip}:30888

2. Login with user *admin* and password *Password1#*.

3. Configure your SMTP server settings.

4. Go through remaining configuration screens and accept all defaults.

5. Create an organization and project (portworx/portworx).

6. Copy the Organization ID from the settings menu.

7. Create an api key by selecting the Access Management menu and choosing the Api Keys tab. Give the api key Project Owner permissions, copy the public and private keys, and add the pod CIDR to the whitelist (10.42.0.0/24 for example).

## Deploy a MongoDB replicaset

### Create a config map with your ops manager information. Use the organization ID copied in the previous step (5ef4a9faa2f8210071aa6e0c in this example).
```
kubectl create configmap opsman \
  --from-literal="baseUrl=http://opsmanager-svc:8080" \
  --from-literal="projectName=portworx" \
  --from-literal="orgId=5ef4a9faa2f8210071aa6e0c"
```
### Configure a secret with the API Key copied in the previous step (user is the public key and publicApiKey is the private key).
```
kubectl  create secret generic api-key \
  --from-literal="user=RVYSQAQI" \
  --from-literal="publicApiKey=39e172af-0cae-4a17-992b-91aca6a2ece2"
```

### Deploy the replicaset.
```
kubectl apply -f replicaset.yaml
```
### Watch as the replicaset pods come online
You can monitor the MongoDB  object:
```
watch kubectl get mdb my-replica-set
```
When the cluster is ready you will see the following output:
```
NAME             TYPE         STATE     VERSION     AGE
my-replica-set   ReplicaSet   Running   4.2.2-ent   4m28s
```

You will also see that three pods are fully initialized and ready (1/1) the cluster will be available.
```
kubectl get po -l app=my-replica-set-svc -n mongodb
NAME               READY   STATUS    RESTARTS   AGE
my-replica-set-0   1/1     Running   0          2m58s
my-replica-set-1   1/1     Running   0          2m22s
my-replica-set-2   1/1     Running   0          2m11s
```
You will also see your processes in the ops manager project UI.

### Insert some data
1. Using the ops manager UI navigate to your project and select my-replica-set from the processes tab.
2. Select the Data tab.
3. Create a database and collection (pxdemo/pxdemo)
4. Insert document












