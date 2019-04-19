for sc in $(kubectl get sc | grep -v NAME | awk '{print $1}')
 do kubectl apply -f $sc.yaml
done
