```
for i in 1 2 3 4 5 6 7 8 9 10; do sed "s/JOB_NAME/dbench-$i/g" dbench.yaml | kubectl apply -f -; sleep 20;  done
```
```
for i in 1 2 3 4 5 6 7 8 9 10 ; do kubectl get po | grep dbench-$i- | awk '{print $1}'| xargs kubectl logs >>fio.log ;  done
```
```
for i in 1 2 3 4 5 6 7 8 9 10; do kubectl delete job dbench-$i ;  done
```
