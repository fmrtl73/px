for sc in $(kubectl get sc | grep -v NAME | grep -v stork | awk '{print $1}')
 do 
    kubectl delete -f $sc.yaml
    init=`echo $sc | sed 's/psql-/pgbench-init-/g'`
    echo $init
    run=`echo $sc | sed 's/psql-/pgbench-run-/g'`
    echo $run
    kubectl delete -f $init.yaml
    kubectl delete -f $run.yaml
done
