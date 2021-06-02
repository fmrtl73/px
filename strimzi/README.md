Deploy the Srtimzi operator and custom resources:
```
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```
Create a producer:
```
kubectl -n kafka run kafka-producer -ti --image=quay.io/strimzi/kafka:0.23.0-kafka-2.8.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9092 --topic my-topic
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
Go to cluster-2 and create the operator with a modification to allow scale to 0 by stork
```
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
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
