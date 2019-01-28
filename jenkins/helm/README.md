# Guide for running an HA Jenkins install with Helm

This guide uses the helm chart here: https://github.com/helm/charts/tree/master/stable/jenkins.

We're going to use dynamic volume provisioning. You'll notice that in the docs you require a pre-existing PVC, but in the values example we can see that a Storage Class can be specified instead.

See here: https://github.com/helm/charts/blob/master/stable/jenkins/values.yaml#L204

First install Helm. Follow this guide: https://docs.helm.sh/using_helm/#installing-helm. On Ubuntu I installed it with Snap.

`sudo snap install helm --classic`

Once it's installed start Tiller. Create a service account for tiller with cluster admin privileges.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
```
`kubectl apply -f tiller-sa.yaml`

Then start Tiller.

`helm init --service-account tiller`

## Create the Portworx Storage Class
For Jenkins we can use a simple Storage Class with repl2 and shared enabled (for multi-instance).

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: px-jenkins-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "2"
  shared: "true"
```
`kubectl apply -f jenkins-sc.yaml`

## Install Jenkins with Helm
Now install the Jenkins chart.

`helm install --name px-jenkins stable/jenkins --set Persistence.StorageClass=px-jenkins-sc`

Check Portworx and you should see the PVC created.

## Testing failover
Once the pod comes up, follow the terminal instructions to retrieve the Jenkins password.

Check the Jenkins port with `kubectl get service`, and use this to access the dashboard with the username admin and you retrieved password. Create an example project so there is some data.

Now run the usual cordon and pod delete commands.

`kubectl cordon <node>` and `kubectl delete pod <jenkins pod>`.

Access the Jenkins dashboard again to verify data persists.

