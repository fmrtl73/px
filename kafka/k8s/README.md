## Kafka Deployment And Benchmarks

Run a 3 node kafka cluster on Portworx with 2 replicas for each kafka broker. Then benchmark the deployment using a set of topics configured with 2 replicas each.

The benchmark scripts is included in the perf-scripts.yaml config map and can easily be modified.

It is recommended to run this benchmark on a 6 node Kubernetes cluster to ensure that all kafka volume replicas are on separate nodes. 

### Deploy Kafka

```
kubectl apply -f px-ha-sc.yaml
kubectl apply -f zk-config.yaml
kubectl apply -f zk-ss.yaml
kubectl apply -f kafka-config.yaml
kubectl apply -f kafka-ss.yaml
kubectl scale sts kafka --replicas=3
```
### Wait for Kafka to finish initializing
```
kubectl wait --for=condition=Ready po/kafka-2 --timeout 5m
```

### Deploy the perfomance benchmark scripts using a config map
```
kubectl apply -f perf-scripts.yaml
```

### Deploy the Producer and Consumer StatefulSets
```
kubectl apply -f kafka-producers.yaml
kubectl apply -f kafka-consumers.yaml
```

### You can also scale the producers and consumers
```
kubectl scale sts kafka-producers --replicas=3
kubectl scale sts kafka-consumers --replicas=3
```

