#!/bin/bash

file=/tmp/disksdb
echo "" > $file

nfs_disks=$(nfsstat -m | grep 'from')
nfs_count=$(nfsstat -m | grep -c "from")
if [ -e /sbin/iscsiadm ];then
isscsi=$(iscsiadm -m session 2>&1)
else
isscsi="iscsiadm: No active sessions."
fi

count=1
while [ $count -le $nfs_count ]; do
    echo "disks[$count]=\"$(nfsstat -m | grep 'from' | sed -n "$count"p | awk 'BEGIN {OFS="|"; t="NFS"; n=" "} {print t, $1, $3, n, n}')\"" >> $file
    count=$((count+1))
done

if [ "$isscsi" != "iscsiadm: No active sessions." ]; then
    iscsi_targets_count=$(iscsiadm -m node | wc -l )
    tg_count=$iscsi_targets_count
        while [ "$tg_count" -gt "0" ]; do
            out=$(iscsiadm -m session -r $tg_count -P 3 | grep -A 5 "Attached SCSI devices:" | sed -n '5,6p')
            out2=$(iscsiadm -m node | sed -n "$tg_count"p | awk 'BEGIN {FS=":"} {print $1}')
            echo "disks[$count]=\"$(echo -n "iSCSI| |"$out2"|"; echo -n $out | awk 'BEGIN {OFS="|"} {print $11, $7}')\"" >> $file
            count=$((count+1))
            tg_count=$((tg_count-1))
        done
fi

sdd=$(fdisk -l 2>/dev/null | egrep '^Disk /dev/sd' | egrep -v 'dm-' |awk '{print $2}' |sed -n 's/://p')
for i in $sdd; do
ven=$(smartctl -i $i |grep Vendor | awk '{print $2}')
sn=$(smartctl -i $i |grep "Serial number:" | awk '{print $3}')
echo "disks[$count]=\"$(echo -n "FC|"$sn"|"$ven"|"$i"|Lun")\"" >> $file
count=$((count+1))
done
