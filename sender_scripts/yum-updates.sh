#!/bin/sh

export LANG=C
export LANGUAGE=

# ensure the package cache is up-to-date
yum -q makecache

# obtain a list of available package updates with their new version
YUM_UPDATES_DETAILS="$(yum check-update | tail -n +3 | awk '{print $1 "=" $2}')"

if [ -z "$YUM_UPDATES_DETAILS" ]; then
  # counting doesn't work correctly if the variable is empty
  YUM_UPDATES_COUNT=0
else
  # count actual lines regardless of line ending (or lack thereof)
  YUM_UPDATES_COUNT="$(printf "%s_" "${YUM_UPDATES_DETAILS}" | grep -c "^")"
fi

# build the stream for zabbix sender
ZBX_STREAM=""
ZBX_STREAM+="- yum.packagestoupdate.count ${YUM_UPDATES_COUNT}\n"
ZBX_STREAM+="- yum.packagestoupdate.details \"$(echo "${YUM_UPDATES_DETAILS}" | tr "\n" " " | xargs)\"\n"

echo -en "${ZBX_STREAM}" | zabbix_sender -c "/etc/zabbix/zabbix_agent2.conf" -i -
