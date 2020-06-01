### Make sure autopilot is properly configured 
Make sure the URL to prometheus is correctly set and the pod is healthy
``` 
kubectl get cm autopilot-config -o yaml -n kube-system
```
Get the pods in kube-system with label name=autopilot
```
kubectl get po -l name=autopilot -n kube-system
```

### Deploy the rule and two datbases in separate namespaces
```
kubectl apply -f autopilotrule-example.yaml
kubectl apply -f namespaces.yaml
kubectl apply -f postgres-sc.yaml
kubectl apply -f postgres-vol.yaml -n pg1
kubectl apply -f postgres-vol.yaml -n pg2
kubectl apply -f postgres-app.yaml -n pg1
kubectl apply -f postgres-app.yaml -n pg2
```

### Monitor the autopilot events
```
kubectl get events --field-selector involvedObject.kind=AutopilotRule,involvedObject.name=volume-resize --all-namespaces --sort-by .lastTimestamp
```

### Monitor the pvc size
```
kubectl get pvc -n pg1 -w
```
