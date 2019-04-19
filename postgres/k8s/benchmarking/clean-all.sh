for sc in $(kubectl get sc | grep -v NAME | grep -v stork | awk '{print $1}')
 do kubectl delete -f $sc.yaml
done
