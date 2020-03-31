##
These instructions assume that you have the greenplum docker images loaded on all your worker nodes.

Refer to the [Greenplum on Kubernetes Documentation](https://greenplum-kubernetes.docs.pivotal.io/1-12/installing.html) for instrcutions on how to get the docker images on to the nodes, you can also push the images to the registry and then edit the files in this repo to use your registry or follow the documentation to use helm to deploy the operator. These instructions do not use HELM.

### Deploy Greenplum Operator
```
kubectl create ns greenplum
kubectl apply -f greenplum-operator-cluster-role.yaml
kubectl apply -f greenplum-operator-service-account.yaml
kubectl apply -f greenplum-operator-cluster-role-binding.yaml
kubectl apply -f greenplum-operator-crds.yaml
kubectl apply -f greenplum-operator.yaml
```
### Check that the operator is running
```
kubectl get po -n greenplum
```
### Deploy Greenplum cluster
```
kubectl apply -f sc.yaml
kubectl apply -f greenplum-cluster.yaml -n greenplum
```
### Patch the segment statefulset to use stork as it's scheduler
```
kubectl patch sts segment-a -p '{"spec":{"template":{"spec": {"schedulerName": "stork"}}}}' -n greenplum
```
