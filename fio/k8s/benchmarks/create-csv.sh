POD=`kubectl -n portworx get po -l job-name=fio-job-fio | grep -v NAME | awk '{print $1}'`
kubectl -n portworx logs $POD > fio-results.json
jq '.jobs[] | select(.jobname | contains("ephemeral"))  | {jobname, groupid, read_iops: .read.iops, write_iops: .write.iops, read_lat: .read.lat.mean, write_lat: .write.lat.mean, read_bw: .read.bw, write_bw: .write.bw }' fio-results.json | jq -r ' flatten | @csv' > /vagrant/fio-results.csv
jq '.jobs[] | select(.jobname | contains("portworx"))  | {jobname, groupid, read_iops: .read.iops, write_iops: .write.iops, read_lat: .read.lat.mean, write_lat: .write.lat.mean, read_bw: .read.bw, write_bw: .write.bw }' fio-results.json | jq -r ' flatten | @csv' >> /vagrant/fio-results.csv
