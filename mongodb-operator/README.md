# MongoDB Operator Deployment with Portworx

## Create a namespace and deploy the operator

```
kubectl create ns mongodb
kubectl apply -f mongodb-enterprise.yaml
```

### Check that it's up and running
```
kubectl get po -n mongodb
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

Deploy the Ops Manager CRD
```
kubectl create -f sc.yaml
kubectl apply -f opsmanager.yaml
```

Check that it is fully initialized
```
kubectl get po -n mongodb
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