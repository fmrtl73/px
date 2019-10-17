sc=$1   # first command line argument
if [ $# -eq 0 ]; then
    echo "please enter the storage class name as a parameter, example: create-csv.sh fio-repl1"
    exit 1
fi


POD=`kubectl -n portworx get po -l job-name=fio-job-$1 | grep -v NAME | awk '{print $1}'`
kubectl -n portworx logs $POD > fio-results.json
jq '.jobs[] | select(.jobname | contains("ephemeral"))  | {jobname, groupid, read_iops: .read.iops, write_iops: .write.iops, read_lat: .read.lat.mean, write_lat: .write.lat.mean, read_bw: .read.bw, write_bw: .write.bw }' fio-results.json | jq -r ' flatten | @csv' > fio-results.csv
jq '.jobs[] | select(.jobname | contains("portworx"))  | {jobname, groupid, read_iops: .read.iops, write_iops: .write.iops, read_lat: .read.lat.mean, write_lat: .write.lat.mean, read_bw: .read.bw, write_bw: .write.bw }' fio-results.json | jq -r ' flatten | @csv' >> fio-results.csv
