kubectl apply -f px-pfc-ds.yaml
PODS=$(kubectl get pods | grep px-pre-flight-check | awk '{print $1}')
for POD in ${PODS}; do
    sp="/-\|"
    sc=0
    while [[ $(kubectl get pod ${POD} -o go-template --template "{{.status.phase}}") != "Running" ]]; do
        printf "\b${sp:sc++:1}"
        ((sc==${#sp})) && sc=0
        #sleep 1
        #echo -n "."
    done
done
kubectl logs --selector name=px-pfc
kubectl delete -f px-pfc-ds.yaml
echo "For more infor on installation prerequisites visit: "
echo "\033[0;34mhttps://docs.portworx.com/start-here-installation/#installation-prerequisites\033[0m"
