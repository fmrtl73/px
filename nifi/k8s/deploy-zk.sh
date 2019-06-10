#! /bin/bash
ENV="$1"

if [ -z "$1" ]; then
  echo "No environment selected; using default"
  ENV="default"
fi
echo "Deploying environment $ENV"

vortex --template zookeeper/templates --output zookeeper/deployment -varpath ./zookeeper/environments/$ENV.yaml
kubectl apply -f zookeeper/deployment/ 
