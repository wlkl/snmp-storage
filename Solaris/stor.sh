#!/usr/bin/env bash

file="/tmp/disksdb"
echo "" > $file

nfs_disks=$(nfsstat -m | grep 'from')
nfs_count=$(nfsstat -m | grep -c "from")
count=0

if [ $nfs_count ]; then
count=1
while [ $count -le $nfs_count ]; do
    echo "disks[$count]=\"$(nfsstat -m | grep 'from' | sed -n "$count"p | awk 'BEGIN {OFS="|"; t="NFS"; n=" "} {print t, $1, $3, n, n}')\"" >> $file
    count=$((count+1))
done
fi

scsi=$(iscsiadm list target -vS |sed -n 's/ //g;s/IPaddress(Peer)://p;s/LUN://p;s/OSDeviceName://p' |awk 'BEGIN{RS="";FS="\n";OFS="|";n=" ";t="iSCSI"}{for (i=2;i<=NF;i++)if(i%2==0)print t,n,$1,$(i+1),$i;else continue}')
iscs_count=$(echo "$scsi" | wc -l)

if [ $scsi ]; then
cnt=1
while [ $cnt -le $iscs_count ]; do
  echo "disks[$((cnt+count))]=\"$(echo "$scsi" | sed -n "$cnt"p)\"" >> $file
  cnt=$((cnt+1))
done
count=$((count+cnt))
fi

if [ $count ];then
count=1
fi

sdd=$(cfgadm -al -o show_FCP_dev | awk '{if($2=="disk")print $1}' | tr '[:lower:]' '[:upper:]' | sed -n 's/^C/c/g;s/::/t/g;s/,/d/p')
for sd in $sdd; do
ven=$(luxadm display /dev/rdsk/$sd | sed -n 's/Vendor://p')
sn=$(luxadm display /dev/rdsk/$sd | sed -n 's/Serial Num://p')
echo "disks[$count]=\"FC|$sn|$ven|$sd|Lun\"" >> $file
count=$((count+1))
done

