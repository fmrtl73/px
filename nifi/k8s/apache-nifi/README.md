# kubernetes-nifi-cluster

A nifi cluster running in kubernetes

### Prerequisites

- Apache Nifi with persistent volumes for its backing store using portworx volumes.

- Requires: Portworx cluster should be in running state.

- Create storage class for zookeeper and nifi:

-  kubectl apply -f portworx-sc.yaml

- Requires [vortex]
  - Copy vortex at : /usr/local/bin
  - Make it executable: chmod +x /usr/local/bin/vortex

- Requires [zookeeper] running

from the zookeeper directory run:
```
./build_environment.sh small
kubectl create -f deployment/
```

Now zookeeper is setup with three nodes on the zk namespace you are ready!

Make sure zk is running to avoid headaches:

```
kubectl get po,svc -n zk
NAME       READY   STATUS    RESTARTS   AGE
pod/zk-0   1/1     Running   0          58m
pod/zk-1   1/1     Running   0          58m
pod/zk-2   1/1     Running   0          58m

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
service/zk-cs   ClusterIP   10.104.1.184   <none>        2181/TCP            58m
service/zk-hs   ClusterIP   None           <none>        2888/TCP,3888/TCP   58m
```

pvc used by zookeeper to keep data persistent:
```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
datadir-zk-0   Bound    pvc-933111a7-86f2-11e9-916b-000c29a48cb7   10Gi       RWO            portworx-nifi-sc   63m
datadir-zk-1   Bound    pvc-9332cd05-86f2-11e9-916b-000c29a48cb7   10Gi       RWO            portworx-nifi-sc   63m
datadir-zk-2   Bound    pvc-9335766d-86f2-11e9-916b-000c29a48cb7   10Gi       RWO            portworx-nifi-sc   63m
```

To check zookeeper is operational:
```
kubectl exec zk-0 cat /opt/zookeeper/conf/zoo.cfg --namespace=zk
kubectl exec zk-0 zkCli.sh create /hello tushar  --namespace=zk
kubectl exec zk-0 zkCli.sh get /hello  --namespace=zk
```

## Deploy Nifi
from the apache-nifi directory run:
```
./deploy.sh default
```

Once running you should see...
```
kubectl get pods -n nifi 
NAME      READY     STATUS    RESTARTS   AGE
nifi-0    1/1       Running   0          25m
nifi-1    1/1       Running   0          25m
nifi-2    1/1       Running   0          25m

kubectl get svc -n nifi                
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP                          PORT(S)                      AGE
nifi        ClusterIP      None           <none>                               8081/TCP,2881/TCP,2882/TCP   52m
nifi-0      ExternalName   <none>         nifi-0.nifi.nifi.svc.cluster.local   <none>                       52m
nifi-1      ExternalName   <none>         nifi-1.nifi.nifi.svc.cluster.local   <none>                       52m
nifi-2      ExternalName   <none>         nifi-2.nifi.nifi.svc.cluster.local   <none>                       52m
nifi-3      ExternalName   <none>         nifi-3.nifi.nifi.svc.cluster.local   <none>                       52m
nifi-4      ExternalName   <none>         nifi-4.nifi.nifi.svc.cluster.local   <none>                       52m
nifi-http   NodePort       10.107.71.85   <none>                               8080:31638/TCP               52m

kubectl get pvc -n nifi
NAME                          STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
contentrepository-nifi-0      Bound     pvc-c00b39d5-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
contentrepository-nifi-1      Bound     pvc-c0116c25-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
contentrepository-nifi-2      Bound     pvc-c019d7ee-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
databaserepository-nifi-0     Bound     pvc-c00a3682-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
databaserepository-nifi-1     Bound     pvc-c00f87a8-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
databaserepository-nifi-2     Bound     pvc-c017dbe4-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
flowfilerepository-nifi-0     Bound     pvc-c0096aac-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
flowfilerepository-nifi-1     Bound     pvc-c00df6bb-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
flowfilerepository-nifi-2     Bound     pvc-c016020d-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
provenancerepository-nifi-0   Bound     pvc-c008b6bd-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
provenancerepository-nifi-1   Bound     pvc-c0132c86-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
provenancerepository-nifi-2   Bound     pvc-c01aec6b-4710-11e9-b1b0-42010a800055   5Gi        RWO            portworx-nifi-sc       1d
```

---

## Nifi UI

`http://<WORKER_NODE_IP>:<NIFI_HTTP_NODE_PORT>/nifi/`

