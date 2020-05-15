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
## Get Elastic Password
```
PASSWORD=$(kubectl get secret elastic-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode}}')
echo $PASSWORD
```
## Get cluster details from the endpoint
```
ELASTIC_IP=$(kubectl get svc elastic-es-http -n elastic -o jsonpath='{.spec.clusterIP}')
curl -u "elastic:$PASSWORD" -k "https://$ELASTIC_IP:9200"
```
### Deploy Kibana
```
kubectl apply -f kibana.yaml
```
## Monitor Kibana
Watch until you see the HEALTH of kibana turn to green, you will see a single kibana pod launch.
```
watch kubectl get kibana,po -n elastic
```

