# Cheat Sheet:

    Quick reference guide or steps to perform portworx related tasks by kubectl and pxctl:

## Kubernetes:

# Display Pod Name, Node IP, Node Name and Docker ID
`kubectl get pods --all-namespaces -o custom-columns=POD:.metadata.name,NodeIP:.status.hostIP,NodeName:.spec.nodeName,DockerID:.status.containerStatuses[].containerID`

# Display Pod Name and associated Volumes in all namespaces
`kubectl describe pod --all-namespaces | awk -v GPV='kubectl get pvc --all-namespaces' '{ if($1 ~ /^Name:/) print "Pod:", $2; if($1 ~ /ClaimName:/) { while(GPV | getline) if($4 ~ /^pvc/) print " ", $4; close(GPV); } }'`

# Install Portworx with Random Cluster Name from CLI only (no need to go to install.portworx.com to generate spec)
`kubectl apply -f "http://install.portworx.com/?c=$(cat /proc/sys/kernel/random/uuid|cut -f1 -d-)&k=etcd://etcdv3-02.portworx.com:2379&kbver=$(kubectl version --short | awk -Fv '/Server Version: /{print $3}')&stork=true&f=true"`

# Execute PXCTL from Master Node One Time
`kubectl exec -n kube-system $(kubectl get pods -n kube-system | awk '{ if($1 ~ /^portworx-/ && $2 ~ /1\/1/) { print $1; exit; } }') /opt/pwx/bin/pxctl status`

# PXCTL alias on Master Node...
`alias pxctl="kubectl exec -n kube-system $(kubectl get pods -n kube-system | awk '{ if($1 ~ /^portworx-/ && $2 ~ /1\/1/) { print $1; exit; } }') /opt/pwx/bin/pxctl"`

`pxctl status`

`pxctl volume list`

# Node wipe
`curl -fsL https://install.portworx.com/px-wipe | bash`

# Execute command on all PX nodes in K8S
`for node in $(kubectl get pods -n kube-system | awk '{ if($1 ~ /^portworx-/ && $2 ~ /1\/1/) { print $1 } }'); do kubectl exec -n kube-system $node /opt/pwx/bin/pxctl status; done`

# Display "orphaned" volumes, which do not have associated PVCs
`{ kubectl exec -n kube-system $(kubectl get pods -n kube-system | awk '{ if($1 ~ /^portworx-/ && $2 ~ /1\/1/) { print $1; exit; } }') /opt/pwx/bin/pxctl volume list | awk 'BEGIN { getline; } { print $2 }'; kubectl get pvc --all-namespaces | awk 'BEGIN { getline; } { if($3 == "Bound") print $4 }'; } | sort | uniq -u`

# Enable/Disable/Start/Stop Portworx on specific K8S node
`kubectl label nodes <node-name> px/enabled=disable --overwrite`

`kubectl label node <node-name> px/service=stop --overwrite`

`kubectl label node <node-name> px/service=start --overwrite`

`kubectl label nodes --all px/enabled=false --overwrite`

# Disable RBAC
`kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts`

# Kill stuck pods
`kubectl delete pod <podname> --force --grace-period=0`

# Kill stuck PV/PVC
`kubectl delete pv/pvc <pvcname> --force --grace-period=0`

# PV/PVC Stuck in Terminating forever
`PV/PVC can get permanently stuck due to storage object in use protection. For measure of last resort kubectl edit pv/pvc and remove two lines concerning finalizers / protection.`
