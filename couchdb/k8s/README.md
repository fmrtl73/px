# Running Couchbase and Couchbase-operator with Portworx
This guide walks though the installation of couchbase and couchbase-operator backed by portworx.
Note that this guide/ demonstration is on openshift. This can be used on kubernetes also, by replacing `oc` with `kubectl`

## Deploy Couchbase Operator
Clone this repository
```
git clone https://github.com/portworx/couchbase-px.git
cd couchbase-px/couchbase-autonomous-operator-openshift_1.0.0-linux_x86_64
```

On an Openshift master node, execute:
```
oc login -u system:admin
```
Apply the pre-requisites for Couchbase-Operator
```
oc create -f crd.yaml
oc create -f cluster-role-sa.yaml
oc create serviceaccount couchbase-operator --namespace default
oc create clusterrolebinding couchbase-operator-rolebinding --clusterrole couchbase-operator --serviceaccount default:couchbase-operator
```

Create docker pull secrets to pull from `registry.connect.redhat.com`. This needs a RedHat account, and the credentials will be stored as a kubernetes secret.
```
# confirm the username/password works  (e.g. user:john-rhel, passwd:s3cret)
docker login -u john-rhel -p s3cret registry.connect.redhat.com
> Login Succeeded

# configure username/password as a kubernetes "docker-registry" secret  (e.g. "regcred")
oc create secret docker-registry regcred --docker-server=registry.connect.redhat.com \
  --docker-username=john-rhel --docker-password=s3cret --docker-email=test@acme.org \
  -n kube-system

```

```
oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com  --docker-username=<yourusername> --docker-password=<yourpassword> --docker-email=<youremail@domain.com>
oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull
```

Now deploy Couchbase-Operator
```
oc create -f operator.yaml
```
Check the status of the deployment using the following commands
```
oc get deploymnents
oc get pods 
```

Now, [install](https://docs.portworx.com/scheduler/kubernetes/openshift-install.html) portworx by going to `https://install.portworx.com/` and apply the generated spec.
Alternatively, you can use the spec in this repository, but make sure to edit it and specify the `clusterID` and `etcdEndPoints`
```
oc secrets add serviceaccount/px-account secrets/regcred --for=pull
oc secrets add serviceaccount/default secrets/regcred --for=pull
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:px-account
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:portworx-pvc-controller-account
oc adm policy add-scc-to-user anyuid system:serviceaccount:default:default
oc create -f px.yaml
```

Once portworx is operational on the Openshift cluster, create the storageclasses we're going to use for couchbase
```
oc apply -f ../storageClass-repl1.yaml
oc apply -f ../storageClass-repl2.yaml
```

Finally deploy persistent couchbase cluster using portworx volumes
```
oc create -f secret.yaml 
oc create -f couchbase-persistent-cluster.yaml
```



