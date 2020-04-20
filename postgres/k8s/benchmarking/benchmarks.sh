pod=$(kubectl get po | grep postgres | awk '{print $1}')
echo "starting test 1"
kubectl exec $pod -- psql -c "create database benchtest1" &>> bench1.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 100 benchtest1 &>> bench1.log
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench1.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 60 benchtest1 &>> bench1.log
### test 2
echo "Starting test 2"
kubectl exec $pod -- psql -c "create database benchtest2" &>> bench2.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 800 benchtest2 &>> bench2.log
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench2.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 benchtest2 &>> bench2.log
### test 3
echo "Starting test 3"
kubectl exec $pod -- psql -c "create database benchtest3" &>> bench3.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 2000 benchtest3 &>> bench3.log
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench3.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 benchtest3 &>>bench3.log
### test 4
echo "Starting test 4"
kubectl exec $pod -- psql -c "create database benchtest4" &>> bench4.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 1500 benchtest4 &>> bench4.log
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench4.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 benchtest4 &>> bench4.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 -S benchtest4 &>> bench4.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 -N benchtest4 &>> bench4.log
### test 5
echo "Starting test 5"
kubectl exec $pod -- psql -c "create database benchtest5" &>> bench5.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 200 benchtest5 &>> bench5.log
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench5.log
kubectl exec $pod -- pgbench -c 1 -T 600 benchtest5 &>> bench5.log
kubectl exec $pod -- pgbench -c 16 -j 4 -T 600 benchtest5 &>> bench5.log
kubectl exec $pod -- pgbench -c 64 -j 8 -T 600 benchtest5 &>> bench5.log
kubectl exec $pod -- pgbench -c 64 -j 8 -T 600 -N benchtest5 &>> bench5.log
kubectl exec $pod -- pgbench -c 16 -j 4 -T 600 -C benchtest5 &>> bench5.log
### test 6
echo "Starting test 6"
kubectl exec $pod -- psql -c "create database benchtest6" &>> bench6.log
t1=$(date +%s)
kubectl exec $pod -- pgbench -i -s 1500 benchtest6 &>> bench6.log
e=$((t2 - t1))
t2=$(date +%s)
e=$((t2 - t1))
echo "elapsted time =" $e &>> bench6.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 benchtest6 &>> bench6.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 -M prepared benchtest6 &>> bench6.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 -S benchtest6 &>> bench6.log
kubectl exec $pod -- pgbench -c 8 -j 4 -T 600 -M prepared -S benchtest6 &>> bench6.log

