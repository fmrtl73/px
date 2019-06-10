port=`kubectl get svc nifi-http -n nifi -o yaml | grep nodePort| awk '{printf $2}'`
nifiURL="http://nifi.px:$port/nifi/"
echo $nifiURL
