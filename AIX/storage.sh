#!/bin/bash

. /tmp/disksdb
MY_OID=".1.3.6.1.4.1.31416.1.5" ;
REQ_OID="${2#$MY_OID}" ;
#REQ_TYPE="$1" ;
MAXITEMS=5

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

#case "${REQ_TYPE}" in
#        -n)
#                getNext $REQ_OID
#                ;;
#        -s)
#                exit 0
#                ;;
#        -g)
#                REQUEST=$REQ_OID
#                OBJECTID=$(echo $REQUEST | awk 'BEGIN { FS="." } { print $4 }')
#                OBJECTTYPE=$(echo $REQUEST | awk 'BEGIN { FS="." } { print $3 }')
#                getData ${OBJECTTYPE} ${OBJECTID}
#                RETOID="$MY_OID.1.${OBJECTTYPE}.${OBJECTID}\n"
#                ;;
#        *)
#                exit 0
#                ;;
#
#	esac

printf "${RETOID}${RETVAL}"
exit ${EXITVAL}
