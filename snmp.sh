#!/bin/bash

export LANG="fr_FR.UTF-8"

usage() {
echo "Usage :check_ntp_nb_client.sh
       -H Hostname to check
	-C Community SNMP
        -w Warning (means maximun number of Clients) 
        -c Critical (means minimum number of Clients)"
exit2
}


if [ "${8}" = "" ]; then usage; fi

ARGS=$(echo "$@" |sed -e 's:-[a-Z] :\n&:g' | sed -e 's: ::g')

for i in $ARGS; do
        if [ -n "$(echo ${i} | grep "^\-C")" ]; then COMMUNITY=$(echo ${i} | cut -c 3-); if [ ! -n "${COMMUNITY}" ]; then usage;fi;fi
        if [ -n "$(echo ${i} | grep "^\-H")" ]; then HOSTTARGET=$(echo ${i} | cut -c 3-); if [ ! -n "${HOSTTARGET}" ]; then usage;fi;fi
        if [ -n "$(echo ${i} | grep "^\-w")" ]; then WARNING=$(echo ${i} | cut -c 3-); if [ ! -n "${WARNING}" ]; then usage;fi;fi
        if [ -n "$(echo ${i} | grep "^\-c")" ]; then CRITICAL=$(echo ${i} | cut -c 3-); if [ ! -n "${CRITICAL}" ]; then usage;fi;fi
done


if [ ! -d /tmp/tmp-control-wifi-check_2/${HOSTTARGET} ]; then mkdir -p /tmp/tmp-control-wifi-check_2/${HOSTTARGET}; fi
TMPDIR="/tmp/tmp-check_ntp_nb_client/${HOSTTARGET}"
# T-1 = 
if [ -f $TMPDIR/check_ntp_nb_client_out.txt ]
	then 
previous=$(cat $TMPDIR/check_ntp_nb_client_out.txt)
check_actual=$(snmpwalk -v 2c -c $COMMUNITY $HOSTTARGET -O 0qv 1.3.6.1.4.1.8955.1.8.2.3.0 | sed -e 's: "$:":g')
else 
snmpwalk -v 2c -c $COMMUNITY $HOSTTARGET -O 0qv 1.3.6.1.4.1.8955.1.8.2.3.0 | sed -e 's: "$:":g'	> $TMPDIR/check_ntp_nb_client_out.txt
echo "OK: $LOAD number of $CONNECTEDAP Managed.  :$LOAD"
exit 0
fi


if [ "$(cat $TMPDIR/snmpwalk_out.txt | head -1)" = "" ]; then 
	echo "CRITICAL: Interogation Controleur WIFI impossible."
	rm -rf ${TMPDIR}
	exit 2
fi

#LOAD=$(cat $TMPDIR/snmp_out.txt | grep "${CONNECTEDAP}" | wc -l)
#LOAD=$(cat $TMPDIR/snmp_out.txt | grep "${CONNECTEDAP}" | sed -e 's:"::g' | tr '\n' ';')
LOAD=$(cat "$TMPDIR/snmpwalk_out.txt")



if [ "$LOAD" -lt "$CRITICAL" ]; then
	echo "WARNING: less than $CRITICAL AP Managed:$LOAD  :$LIST"
	rm -rf "${TMPDIR}"	
	exit 1
fi
if [ "$LOAD" -gt "$WARNING" ]; then
	echo "WARNING: More then $WARNING AP are currently Managed: $LOAD   :$LIST"
	rm -rf "${TMPDIR}"
	exit 1
fi
echo "OK: $LOAD number of $CONNECTEDAP Managed.  :$LOAD"
rm -rf "${TMPDIR}"
exit 0
