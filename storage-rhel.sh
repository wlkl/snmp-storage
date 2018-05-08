#!/bin/bash

#. /etc/snmp/disksdb
nfs_disks=$(nfsstat -m | grep 'from')
nfs_count=$(nfsstat -m | grep -c "from")
isscsi=$(iscsiadm -m session 2>&1)

count=1
while [ $count -le $nfs_count ]; do
    disks[$count]=$(nfsstat -m | grep 'from' | sed -n "$count"p | awk 'BEGIN {OFS="|"; t="NFS"; n=" "} {print t, $1, $3, n, n}')
    count=$((count+1))
done

if [ "$isscsi" != "iscsiadm: No active sessions." ]; then
for i in $(iscsiadm -m session | awk '{print $2}' | sed -n '{s/\[//; s/\]//p}') # goes through all sessions
do
d=$(iscsiadm -m session -r $i -P3 | grep "Attached scsi disk" | awk '{print $4}') # and find disks names
if [[ $(echo $d |wc -w) > 1 ]] # if session has two or more disks
  then
  ip=$(iscsiadm -m session -r 6 -P 3 |grep "Current Portal:" |awk 'BEGIN {FS=":"} {print $2}')
  for a in $d
  do
    lun=$(iscsiadm -m session -r $i -P 3 | sed -n -e '/'$a'/{x;p;d}' -e x | awk '{print $7}') # goes through them and print lun
    disks[$count]=$(echo -n "iSCSI| |"$ip"|"$a"|"$lun)
    count=$((count+1))
  done
  else
  ip2=$(iscsiadm -m session -r 6 -P 3 |grep "Current Portal:" |awk 'BEGIN {FS=":"} {print $2}')
  lun2=$(iscsiadm -m session -r $i -P 3 | sed -n -e '/'$(iscsiadm -m session -r $i -P3 | grep "Attached scsi disk" | awk '{print $4}')'/{x;p;d}' -e x | awk '{print $7}')
  disks[$count]=$(echo -n "iSCSI| |"$ip2"|"$d"|"$lun2)
  count=$((count+1))
fi
done
fi

getData() {

   RETVAL="string\n"
   RETVAL="$RETVAL$(echo ${disks[$2]} |cut -d'|' -f$1)\n"
   EXITVAL=0

}

getNext() {
        REQUEST=$1
        NUM=${#disks[*]}
        # Always start at .3.1.1
        if [[ "$REQUEST" == "" ]]; then
                REQUEST=".3.1.0"
        fi
        OBJECTID=$(echo $REQUEST | awk 'BEGIN { FS="." } { print $4 }')
        OBJECTTYPE=$(echo $REQUEST | awk 'BEGIN { FS="." } { print $3 }')
        if [ "$OBJECTID" == "" ]; then
                let OBJECTID=0
        fi
        let OBJECTID=$OBJECTID
        let OBJECTTYPE=$OBJECTTYPE
        # Get next entry
        if [ $OBJECTID -le $NUM ]; then
                let OBJECTID=${OBJECTID}+1
        fi
		# Get next category if no more lines
        if [ $OBJECTID -gt $NUM ]; then
                let OBJECTTYPE=${OBJECTTYPE}+1
                let OBJECTID=1
        fi
		# Stop when no more categories
        if [ $OBJECTTYPE -gt ${MAXITEMS} ]; then
                exit 0
        fi
        getData ${OBJECTTYPE} ${OBJECTID}
        RETOID="$MY_OID.1.${OBJECTTYPE}.${OBJECTID}\n"
}

MY_OID=".1.3.6.1.4.1.31416.1.5" # Set in /etc/snmp/snmpd.conf
REQ_OID="${2#$MY_OID}" # Strip MY_OID from requested OID
REQ_TYPE="$1" # n,g(GET),s(SET)
MAXITEMS=5

while getopts "n:g:s" opt
do
case $opt in
n)  getNext $REQ_OID
    ;;
s)  exit 0
    ;;
g)  OBJECTID=$(echo $REQ_OID | awk 'BEGIN { FS="." } { print $3 }')
    OBJECTTYPE=$(echo $REQ_OID | awk 'BEGIN { FS="." } { print $2 }')
    getData ${OBJECTTYPE} ${OBJECTID}
    RETOID="$MY_OID.1.${OBJECTTYPE}.${OBJECTID}\n"
    ;;
*)  exit 0
    ;;
esac
done

printf "${RETOID}${RETVAL}"
exit ${EXITVAL}
