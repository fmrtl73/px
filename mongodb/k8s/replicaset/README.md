# Deployment Instructions
### create namespace
```
kubectl create ns mongo-rs
```
### create secret to for mongo key
```
kubectl create secret generic mongo-key --from-file=id_rsa=/vagrant/id_rsa -n mongo-rs
```
### create service account for mongo
```
kubectl apply -f sa.yaml
```
### create portworx storage class and volume placement strategy
```
kubectl apply -f sc.yaml
kubectl apply -f vps.yaml
```
### deploy the mongo configmap and statefulset
```
kubectl apply -f configmap.yaml
kubectl apply -f sts.yaml
```
### wait till sts initializes all 3 mongo-rs pods
```
kubectl get po -n mongo-rs -w
```
### initialize the statefulset 
```
kubectl apply -f mongo-init-job.yaml
```
