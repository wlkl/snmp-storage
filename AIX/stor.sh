#!/bin/bash

file=/tmp/disksdb
echo "" > $file
fc_disks=$(lsdev -Cc disk |grep Available |grep FC |awk '{print $1}')

hex2dec(){
hex=$(echo $1 | sed -e 's/^0x//' -ne 's/[0]*$//p')
echo $((16#$hex))
}

count=1
for i in $fc_disks; do
man=$(lscfg -vl $i |grep Manufacturer | sed -n 's/[ ]*Manufacturer[.]*//p')
hex_lun=$(lsattr -El $i |grep lun_id |awk '{print $2}')
node_id=$(lsattr -El $i |grep node_name |awk '{print $2}' |sed -n 's/^0x//p')
lun=$(hex2dec $hex_lun)
echo "disks[$count]=\"FC|$node_id|$man|$i|$lun\"" >> $file
count=$((count+1))
done



