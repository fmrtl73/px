ENV="$1"

if [ -z "$1" ]; then
  echo "No environment selected; using default"
  ENV="default"
fi
echo "Building for environment $ENV"


rm -rf apache-nifi/deployment || true

vortex --template apache-nifi/templates --output apache-nifi/deployment -varpath ./apache-nifi/environments/$ENV.yaml

kubectl create -f apache-nifi/deployment/
