#!/bin/bash
go run /opt/massconfigure.go > /opt/masscan.conf

envsubst < zgrab2-template.ini > zgrab2.ini

PORT_TO_SCAN=`echo $PORT_TO_SCAN`
SUBNET_TO_SCAN=`echo $SUBNET_TO_SCAN`
TASK_DEFINITION=`echo $TASK_DEFINITION | awk -F / '{print $1}'`
declare -A zgrabdict=( ["21"]="ftp" ["143"]="imap" ["27017"]="mongodb" ["3306"]="mysql" ["1433"]="mssql" ["1521"]="oracle" ["110"]="pop3" ["5432"]="postgres" ["6379"]="redis" ["102"]="siemens" ["139"]="smb" ["25"]="smtp" ["22"]="ssh" ["23"]="telnet")
declare -A ipdict
echo masscan config file:
echo
cat /opt/masscan.conf

# echo zgrab2 config file:
echo
# cat zgrab2.ini

# wait few seconds before start while network card going to meltdown
sleep 5

OUT1=/opt/out/masscan-$TASK_DEFINITION.out
OUT2=/opt/out/zgrab2-$TASK_DEFINITION.out

masscan -p$PORT_TO_SCAN $SUBNET_TO_SCAN --exclude 255.255.255.255 --rate 10000000 -c /opt/masscan.conf | tee $OUT1 2>&1
echo masscan ips:
echo
# cat $OUT1 | awk '{print $6}'
echo zgrab2 ips:
echo
# PORT_TO_SCAN = cat $OUT1 | awk -F " " '{print $4}' | awk -F "/" '{print $1}' | tr '\n' ',' | sed 's/,$//'
# IP = cat $OUT1 | awk '{print $6}'
# Loop to make dictionary of Port:IPs 

while read line; do
    data=$(echo $line | awk '{print $6}')
    key=$(echo $line | awk -F " " '{print $4}' | awk -F "/" '{print $1}' | tr '\n' ',' | sed 's/,$//')
    ipdict[$key]="${ipdict[$key]}${ipdict[$key]:+,}$data"
done < $OUT1

# Loop to scan and make output file of each Port/Service which has been scanned
for i in "${!zgrabdict[@]}"
do
    echo "${ipdict[$i]}" | sed -e $'s/,/\\\n/g' | zgrab2 "${zgrabdict[$i]}" >> /opt/out/zgrab2-$TASK_DEFINITION-${zgrabdict[$i]}.out
done
# cat $OUT1 | awk '{print $6}' | zgrab2 -o /opt/out/output-$TASK_DEFINITION.txt | jq -r '. | select(.data.http.result.response.body != null) | select(.data.http.result.response.body|test("lucene_version")) | .ip' | tee $OUT2 2>&1
