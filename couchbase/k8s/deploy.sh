kubectl create -f sc.yaml
kubectl create -f operator-role.yaml
kubectl create -f operator-role-binding.yaml
kubectl create -f operator-service-account.yaml
kubectl create -f crd.yaml
kubectl apply -f operator-deployment.yaml
kubectl create -f secret.yaml
