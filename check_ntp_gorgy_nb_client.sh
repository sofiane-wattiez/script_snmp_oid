#!/bin/bash

export LANG="fr_FR.UTF-8"

usage() {
echo "Usage :check_ntp_gorgy_nb_client.sh
       -H Hostname to check
	-C Community SNMP
        -w Warning (means maximun number of Clients) 
        -c Critical (means minimum number of Clients)"
exit 2
}


if [ "${8}" = "" ]; then usage; fi

ARGS=$(echo "$@" |sed -e 's:-[a-Z] :\n&:g' | sed -e 's: ::g')

for i in $ARGS; do
        if echo "${i}" | grep -q "^\-C"; then COMMUNITY=$(echo "${i}" | cut -c 3-); if [ -z "${COMMUNITY}" ]; then usage;fi;fi
        if echo "${i}" | grep -q "^\-H"; then HOSTTARGET=$(echo "${i}" | cut -c 3-); if [ -z "${HOSTTARGET}" ]; then usage;fi;fi
        if echo "${i}" | grep -q "^\-w"; then WARNING=$(echo "${i}" | cut -c 3-); if [ -z "${WARNING}" ]; then usage;fi;fi
        if echo "${i}" | grep -q "^\-c"; then CRITICAL=$(echo "${i}" | cut -c 3-); if [ -z "${CRITICAL}" ]; then usage;fi;fi
done

TMPDIR="/tmp/tmp-check_ntp_gorgy_nb_client/${HOSTTARGET}"
# If the directory does not exist, create it
if [ ! -d "${TMPDIR}" ]; then mkdir -p "${TMPDIR}";fi

# If file does exist
if [ -f "$TMPDIR/check_ntp_gorgy_nb_client_out.txt" ]
then 
	previous=$(cat "$TMPDIR/check_ntp_gorgy_nb_client_out.txt")
	check_actual=$(snmpwalk -v 2c -c "$COMMUNITY" "$HOSTTARGET" -O 0qv 1.3.6.1.4.1.8955.1.8.2.3.0 | sed -e 's: "$:":g')
	delta=$((check_actual-previous))
    perfdata="'perf_nb_client'=${delta}"

	if [ "$delta" -ge "$CRITICAL" ]
	then
		echo "CRITICAL: less than critical limit $CRITICAL: $delta clients connected |${perfdata}"
		echo "$check_actual" > "$TMPDIR/check_ntp_gorgy_nb_client_out.txt"
		exit 2
	elif [ "$delta" -ge "$WARNING" ]
	then
		echo "WARNING: less than warning limit $WARNING: $delta clients connected |${perfdata}"
		echo "$check_actual" > "$TMPDIR/check_ntp_gorgy_nb_client_out.txt"
		exit 1
	else
		echo "OK: $delta clients connected |${perfdata}"
		echo "$check_actual" > "$TMPDIR/check_ntp_gorgy_nb_client_out.txt"
		exit 0
	fi
else 
	if check_actual=$(snmpwalk -v 2c -c "$COMMUNITY" "$HOSTTARGET" -O 0qv 1.3.6.1.4.1.8955.1.8.2.3.0 | sed -e 's: "$:":g')
	then
		echo "WARNING: waiting others values"
		echo "$check_actual" > "$TMPDIR/check_ntp_gorgy_nb_client_out.txt"
		exit 1
	else
		echo "UNKNOWN: Can't get SNMP data"
		exit 3
	fi
fi
