kubectl apply -f https://docs.portworx.com/samples/k8s/grafana/prometheus-operator.yaml
sleep 10
kubectl apply -f service-monitor.yaml
kubectl apply -f https://docs.portworx.com/samples/k8s/grafana/prometheus-rules.yaml
kubectl apply -f https://docs.portworx.com/samples/k8s/grafana/prometheus-cluster.yaml
kubectl apply -f https://docs.portworx.com/samples/k8s/grafana/grafana-deployment.yaml
kubectl apply -f cm.yaml
kubectl apply -f autopilot.yaml
