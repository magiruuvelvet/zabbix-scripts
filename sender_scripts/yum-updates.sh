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

# send the timestamp of the last update check for reliability monitoring
# get informed immediately when update checks stop working
YUM_STATS_TIMESTAMP="$(date -u +%s)"

# build the stream for zabbix sender
ZBX_STREAM=""
ZBX_STREAM+="- yum.packagestoupdate.count ${YUM_UPDATES_COUNT}\n"
ZBX_STREAM+="- yum.packagestoupdate.details \"$(echo "${YUM_UPDATES_DETAILS}" | tr "\n" " " | xargs)\"\n"
ZBX_STREAM+="- yum.stats.timestamp.last_update_check ${YUM_STATS_TIMESTAMP}\n"

echo -en "${ZBX_STREAM}" | zabbix_sender -c "/etc/zabbix/zabbix_agent2.conf" -i -
