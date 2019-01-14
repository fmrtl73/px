# Run the pre-flight check before installing Portworx

## To deploy pre-flight:
```
kubectl apply -f <insert yaml here>
```

## Get the report
```
@TODO:
This should look like `kubectl logs -n kube-system -l <label-selector> --tail=9999`
```

##Cleanup
```
kubectl delete -f <>
```

## `@TODO: add support for checking etcd endpoints`
