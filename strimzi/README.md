Deploy the Srtimzi operator and custom resources:
```
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```
Deploy the cluster:
```
kubectl apply -f kafka-cluster.yaml
```

Create a producer:
```
kubectl -n kafka run kafka-producer -ti --image=quay.io/strimzi/kafka:0.23.0-kafka-2.8.0 --rm=true --restart=Never -- sh
```

Publish a timestamp every 10 seconds
```
while true; do date | ./bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9092 --topic my-topic - ; done
```

In a seperate window, create a consumer:
```
kubectl -n kafka run kafka-consumer -ti --image=quay.io/strimzi/kafka:0.23.0-kafka-2.8.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic my-topic --from-beginning
```

Register Strimzi custom resources with Stork:
```
kubectl apply -f register-strimzi-operator.yaml
```
Go to cluster-2 and create the operator and scale it to 0. 
```
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
kubectl scale deploy strimzi-cluster-operator -n kafka --replicas=0
```

Modify the custom resource for strimzi to allow scale to 0 by stork
```
kubectl patch customresourcedefinition kafkas.kafka.strimzi.io --type='json' -p='[{"op": "replace", "path": "/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/kafka/properties/replicas/minimum", "value":0}]'
kubectl patch customresourcedefinition kafkas.kafka.strimzi.io --type='json' -p='[{"op": "replace", "path": "/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/zookeeper/properties/replicas/minimum", "value":0}]'
```
Start migration (requires cluster-2 clusterpair object to be created and initialized successfully):
```
kubectl apply -f migrationschedule.yaml
```

Get migration to see if it's working
```
storkctl get migrations -n kube-system
```
Finally, on cluster-2 you can activate the migration:
```
storkctl activate migrations -nkafka
```
Once all the pods are up and running you can create a consumer and see all messages until the last migration:
```
kubectl -n kafka run kafka-consumer -ti --image=quay.io/strimzi/kafka:0.23.0-kafka-2.8.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic my-topic --from-beginning
```