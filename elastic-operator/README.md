### Deploy Elastic Search Operator and create elastic namespace
```
kubectl apply -f https://download.elastic.co/downloads/eck/1.1.1/all-in-one.yaml
kubectl create ns elastic
```
## Monitor Operator Logs
```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```
### Deploy Portworx Storage Class
```
kubectl apply -f sc.yaml
```
### Deploy Elastic Search Cluster
```
kubectl apply -f elastic.yaml
```
## Monitor the Elastic Search Status, PVCs, and PODs
Watch until you see the HEALTH of elasticsearch turn to green, you will see 3 PVCs and 3 PODS launch as it moves from phase to phase.
```
watch kubectl get elasticsearch,pvc,po -n elastic
```
## Get cluster details from the endpoint
```
PASSWORD=$(kubectl get secret elastic-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode}}')
ELASTIC_IP=$(kubectl get svc elastic-es-http -n elastic -o jsonpath='{.spec.clusterIP}')
curl -u "elastic:$PASSWORD" -k "https://$ELASTIC_IP:9200"
```
### Deploy Kibana
This configuration uses a NodePort service type. You can edit the kibana.yaml file to change to LoadBalancer, or ClusterIP as you see fit.
```
kubectl apply -f kibana.yaml
```
## Monitor Kibana
Watch until you see the HEALTH of kibana turn to green, you will see a single kibana pod launch.
```
watch kubectl get kibana,po -n elastic
```
## Login to Kibana
Assuming you used a NodePort service type you will be able to login at the url these command will output:
```
nodeip=$(kubectl get nodes --selector=kubernetes.io/role!=master -o jsonpath={.items[0].status.addresses[?\(@.type==\"InternalIP\"\)].address})
nodeport=$(kubectl get svc kibana-kb-http -n elastic -o jsonpath='{.spec.ports[0].nodePort}')
echo "https://$nodeip:$nodeport"
```
You will get a certificate error, just proceed and login with the following username and password:
```
username=elastic
password=$(kubectl get secret elastic-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
echo "username: $username, password: $password"
```