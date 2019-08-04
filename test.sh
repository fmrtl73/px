NS=default
while true; do
  # if the readonly cm is present then iterate through it's deployments
  kubectl -n $NS get cm readonly &> /dev/null
  if (( $? )); then
     echo "config map readonly doesn't exist in namepsace" $NS
     sleep 10
  else 
    APP_NAME=`kubectl get cm readonly -o yaml | grep deploy | awk '{print $2}'`
    echo $APP_NAME
    kubectl -n $NS delete cm readonly
  fi
done
