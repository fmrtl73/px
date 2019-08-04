NS=default
while true; do
  # if the readonly cm is present then iterate through it's deployments
  kubectl -n $NS get cm readonly &> /dev/null
  if (( $? )); then
     echo "config map readonly doesn't exist in namepsace" $NS
     sleep 10
  else
    mkdir tmp
    echo "get deployment spec"
    # get the deployment spec
    APP_NAME=`kubectl -n $NS get cm readonly -o yaml | grep deploy | awk '{print $2}'`
    SVC_NAME=`kubectl -n $NS get cm readonly -o yaml | grep svc | awk '{print $2}'`
    REPLICAS=`kubectl -n $NS get cm readonly -o yaml | grep replicas | awk '{print $2}' | sed 's/"//g'`

    echo "parse pvc name"
    # parse out the pvc name
    PVC_NAME=`kubectl describe deploy $APP_NAME | grep ClaimName | awk '{print $2}'`

    echo "get old snapshot "
    # get previous snap
    OLD_SNAP_NAME=`storkctl get snap | grep $PVC_NAME-snap | awk '{print $1}'`
    OLD_PVC_CLONE_NAME=`kubectl get pvc | grep $PVC_NAME-clone | awk '{print $1}'`

    echo "create new snapshot"
    # create snapshot
    TIME=`date +%s`
    NEW_SNAP_NAME=$PVC_NAME-snap-$TIME
    echo $NEW_SNAP_NAME
    storkctl -n $NS create snap -p $PVC_NAME $NEW_SNAP_NAME

    echo "clone snapshot"
    # clone the new snapshot
    NEW_PVC_CLONE_NAME=$PVC_NAME-clone-$TIME
    PVC_SIZE=`kubectl -n $NS get pvc $PVC_NAME | grep $PVC_NAME | awk '{print $4}'`
    echo "storkctl -n $NS create pvc -a "ReadOnlyMany" -s $NEW_SNAP_NAME --size $PVC_SIZE $NEW_PVC_CLONE_NAME"
    storkctl -n $NS create pvc -a "ReadOnlyMany" -s $NEW_SNAP_NAME --size $PVC_SIZE $NEW_PVC_CLONE_NAME

    echo "update deploy"
    #create a new readonly deployment file and apply
    kubectl -n $NS get deploy $APP_NAME-ro -o yaml > tmp/$APP_NAME-ro.yaml
    if (( $? )); then
      kubectl -n $NS get deploy $APP_NAME -o yaml > tmp/$APP_NAME.yaml
      sed "s/$APP_NAME/$APP_NAME-ro/g" tmp/$APP_NAME.yaml > tmp/$APP_NAME-ro.yaml
      sed -i '/last-applied-configuration/d' tmp/$APP_NAME-ro.yaml
      sed -i '/{/d' tmp/$APP_NAME-ro.yaml
      sed -i '/revision/d' tmp/$APP_NAME-ro.yaml
      sed -i '/selfLink/d' tmp/$APP_NAME-ro.yaml
      sed -i '/uid/d' tmp/$APP_NAME-ro.yaml
      sed -i "s/$PVC_NAME/$NEW_PVC_CLONE_NAME/g" tmp/$APP_NAME-ro.yaml
      kubectl -n $NS apply -f tmp/$APP_NAME-ro.yaml
      kubectl scale deploy $APP_NAME-ro --replicas $REPLICAS
    else
      sed -i "s/$OLD_PVC_CLONE_NAME/$NEW_PVC_CLONE_NAME/g" tmp/$APP_NAME-ro.yaml
      kubectl -n $NS apply -f tmp/$APP_NAME-ro.yaml
    fi
    #if it hasn't been created, create a new readonly service file
    kubectl -n $NS get svc $SVC_NAME-ro &> /dev/null
    if (( $? )); then
      echo "svc already exists, not recreating"
    else
      kubectl -n $NS get svc $SVC_NAME -o yaml > tmp/$SVC_NAME.yaml
      sed "s/$APP_NAME/$APP_NAME-ro/g" tmp/$SVC_NAME.yaml > tmp/$SVC_NAME-ro.yaml
      sed -i '/last-applied-configuration/d' tmp/$SVC_NAME-ro.yaml
      sed -i '/{/d' tmp/$SVC_NAME-ro.yaml
      sed -i '/clusterIP/d' tmp/$SVC_NAME-ro.yaml
      sed -i '/uid:/d' tmp/$SVC_NAME-ro.yaml
      sed -i '/selfLink/d' tmp/$SVC_NAME-ro.yaml
      kubectl -n $NS apply -f tmp/$SVC_NAME-ro.yaml
    fi
    echo "cleanup"
    #cleanup
    rm -rf tmp
    for snap in $OLD_SNAP_NAME; do kubectl -n $NS delete volumesnapshot $snap; done
    for clone in $OLD_PVC_CLONE_NAME; do kubectl -n $NS delete pvc $clone; done
    kubectl -n $NS delete cm readonly
  fi
done
