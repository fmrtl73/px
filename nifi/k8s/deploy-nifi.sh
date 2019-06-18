ENV="$1"

if [ -z "$1" ]; then
  echo "No environment selected; using default"
  ENV="default"
fi
echo "Building for environment $ENV"


rm -rf apache-nifi/deployment || true

vortex --template apache-nifi/templates --output apache-nifi/deployment -varpath ./apache-nifi/environments/$ENV.yaml
kubectl create ns nifi
kubectl create -f apache-nifi/deployment/
sleep 6
kubectl -n nifi wait --for=condition=Ready po/nifi-0 --timeout 2m | awk '{print " # " $0}'
  if (( $? )); then
    echo "Failure" >&2
    exit 1
  fi
kubectl cp jars nifi-0:/opt/nifi/lib -n nifi
if kubectl get deployment -n kube-system stork -o yaml | grep migration-admin-namespace | wc -l &> /dev/null; then
  echo "migration-admin-namespace already set" >&2
  exit 1
fi
kubectl get deployment -n kube-system stork -o yaml | sed 's/- --health-monitor-interval=120/- --health-monitor-interval=120\n        - --migration-admin-namespace=nifi/g' | kubectl apply -f -
