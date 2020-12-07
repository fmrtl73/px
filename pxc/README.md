<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.imgur.com/6wj0hh6.jpg" alt="Project logo"></a>
</p>

<h3 align="center">PXC Scripts</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues](https://img.shields.io/github/issues/kylelobo/The-Documentation-Compendium.svg)](https://github.com/kylelobo/The-Documentation-Compendium/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/kylelobo/The-Documentation-Compendium.svg)](https://github.com/kylelobo/The-Documentation-Compendium/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>

---

<p align="center"> Useful PXC scripts automating Portworx using Python.
    <br>
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Deployment](#deployment)


## 🧐 About <a name = "about"></a>

The scripts should all have a usage print out, for example, running the following command should print out the useage for the ds.py script:
```
kubectl pxc script ds.py
```

## 🏁 Getting Started <a name = "getting_started"></a>

Just git clone the repo and change directories to px/pxc to run the scripts. For example, list volumes by datastore using ds.py:

```
kubectl pxc script ds.py list
```
Describe a PVC with name test-vol:
```
kubectl pxc volume describe test-vol
```
Move replicas for PVC test-vol from datastore ds1 to datasotre ds2:
```
kubectl pxc volume move test-vol ds1 ds2
```
Move all PVC replicas from datastore ds1 to datastore ds2:
```
kubectl pxc volume move all ds1 ds2
```
The ds.py script is for migrating volumes from one VSPhere Datastore to another. It assumes your cluster is setup to use different datastores on different nodes. For example you can achieve this by creating multiple daemonsets with different datastore settings:

## 🏁 Deployment <a name = "deployment"></a>

First label your worker nodes:
```
kubectl label node node-1-1 node-1-2 node-1-3 px/datastore=ds1
kubectl label node node-1-4 node-1-5 node-1-6 px/datastore=ds2
```
Then before applying your spec, clone the daemonset section and name each daemonset portworx-ds1 and portworx-ds2. Modify the spec.affinity section to look for the above labels.

For daemonset-ds1:
```
affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: px/enabled
                operator: NotIn
                values:
                - "false"
              - key: px/datastore
                operator: In
                values:
                - ds1
              - key: node-role.kubernetes.io/master
                operator: DoesNotExist
```
For daemonset-ds2:
```
affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: px/enabled
                operator: NotIn
                values:
                - "false"
              - key: px/datastore
                operator: In
                values:
                - ds2
              - key: node-role.kubernetes.io/master
                operator: DoesNotExist
```


And modify the VSPhere datastore prefix to match the right datstore.

For daemonset-ds1:
```
      - name: VSPHERE_DATASTORE_PREFIX
          value: ' sn1-x70-f06-27-vc01-ds01'
```
For daemonset-ds2:
```
      - name: VSPHERE_DATASTORE_PREFIX
          value: ' sn1-x70-f06-27-vc01-ds02'
```
With that configured you will see the datastore names when you run the `kubectl pxc script ds.py list` command:
```
kubectl pxc script ds.py list
datastore sn1-x70-f06-27-vc01-ds01 is used on the following nodes: ['node-1-1', 'node-1-3', 'node-1-2']
     volumes_replicas:
         - []
datastore sn1-x70-f06-27-vc01-ds02 is used on the following nodes: ['node-1-5', 'node-1-4', 'node-1-6']
     volumes_replicas:
         - []
```
You can create some volumes to test with, first create a storage class:
```
cat <<EOF | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: px-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"
EOF
```
Then create some PVCs:
```
cat <<EOF > pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-vol
  annotations:
    volume.beta.kubernetes.io/storage-class: px-sc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
```

```
for i in {0..10}; do sed "s/test-vol/test-vol-$i/g" pvc.yaml | kubectl apply -f -; done
```
You should now see volume replicas on both datastores:
```
kubectl pxc script ds.py list
datastore sn1-x70-f06-27-vc01-ds02 is used on the following nodes: ['node-1-6', 'node-1-5', 'node-1-4']
     volumes_replicas:
         - test-vol-6
         - test-vol-2
         - test-vol-4
         - test-vol-7
         - test-vol-8
         - test-vol-9
         - test-vol-10
         - test-vol-0
         - test-vol-3
         - test-vol-5
datastore sn1-x70-f06-27-vc01-ds01 is used on the following nodes: ['node-1-2', 'node-1-1', 'node-1-3']
     volumes_replicas:
         - test-vol-6
         - test-vol-2
         - test-vol-4
         - test-vol-7
         - test-vol-8
         - test-vol-9
         - test-vol-10
         - test-vol-3
         - test-vol-1
         - test-vol-5
```
Then you will be able to move all your volumes from one datstore to the other:

```
kubectl pxc script ds.py move all sn1-x70-f06-27-vc01-ds01 sn1-x70-f06-27-vc01-ds02
```
Ouput (be patient, pxc only dumps all the output once the script is done executing):
```
Moving volume test-vol-1 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-1 is replicated on nodes ['node-1-3', 'node-1-1', 'node-1-2']
   - removing replica from node: node-1-3
   - adding replica to node node-1-6
   - removing replica from node: node-1-1
   - adding replica to node node-1-4
   - removing replica from node: node-1-2
   - adding replica to node node-1-5
Moving volume test-vol-5 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-5 is replicated on nodes ['node-1-2', 'node-1-6', 'node-1-5']
   - removing replica from node: node-1-2
   - adding replica to node node-1-4
Moving volume test-vol-6 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-6 is replicated on nodes ['node-1-3', 'node-1-2', 'node-1-4']
   - removing replica from node: node-1-3
   - adding replica to node node-1-6
   - removing replica from node: node-1-2
   - adding replica to node node-1-5
Moving volume test-vol-9 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-9 is replicated on nodes ['node-1-1', 'node-1-2', 'node-1-5']
   - removing replica from node: node-1-1
   - adding replica to node node-1-6
   - removing replica from node: node-1-2
   - adding replica to node node-1-4
Moving volume test-vol-10 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-10 is replicated on nodes ['node-1-3', 'node-1-1', 'node-1-5']
   - removing replica from node: node-1-3
   - adding replica to node node-1-6
   - removing replica from node: node-1-1
   - adding replica to node node-1-4
Moving volume test-vol-2 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-2 is replicated on nodes ['node-1-3', 'node-1-6', 'node-1-5']
   - removing replica from node: node-1-3
   - adding replica to node node-1-4
Moving volume test-vol-4 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-4 is replicated on nodes ['node-1-3', 'node-1-1', 'node-1-4']
   - removing replica from node: node-1-3
   - adding replica to node node-1-6
   - removing replica from node: node-1-1
   - adding replica to node node-1-5
Moving volume test-vol-7 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-7 is replicated on nodes ['node-1-1', 'node-1-6', 'node-1-5']
   - removing replica from node: node-1-1
   - adding replica to node node-1-4
Moving volume test-vol-8 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-8 is replicated on nodes ['node-1-3', 'node-1-6', 'node-1-4']
   - removing replica from node: node-1-3
   - adding replica to node node-1-5
Moving volume test-vol-3 from datastore sn1-x70-f06-27-vc01-ds01 to datastore sn1-x70-f06-27-vc01-ds02
 - volume test-vol-3 is replicated on nodes ['node-1-1', 'node-1-2', 'node-1-4']
   - removing replica from node: node-1-1
   - adding replica to node node-1-6
   - removing replica from node: node-1-2
   - adding replica to node node-1-5
```

