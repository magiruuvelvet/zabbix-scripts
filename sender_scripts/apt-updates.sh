#!/bin/sh

export LANG=C
export LANGUAGE=

# obtain a list of available package updates
APT_UPDATE_DETAILS="$(apt-get -s upgrade)"

# extract total updates
APT_TOTAL_UPDATES_COUNT="$(echo "$APT_UPDATE_DETAILS" | grep -iPc '^Inst((?!security).)*$' | tr -d '\n')"

# extract total security updates
APT_SECURITY_UPDATES_COUNT="$(echo "$APT_UPDATE_DETAILS" | grep -ci ^inst.*security | tr -d '\n')"

# send the timestamp of the last update check for reliability monitoring
# get informed immediately when update checks stop working
APT_STATS_TIMESTAMP="$(date -u +%s)"

# build the stream for zabbix sender
ZBX_STREAM=""
ZBX_STREAM+="- apt.packagestoupdate.count.total ${APT_TOTAL_UPDATES_COUNT}\n"
ZBX_STREAM+="- apt.packagestoupdate.count.security ${APT_SECURITY_UPDATES_COUNT}\n"
ZBX_STREAM+="- apt.stats.timestamp.last_update_check ${APT_STATS_TIMESTAMP}\n"

echo -en "${ZBX_STREAM}" | zabbix_sender -c "/etc/zabbix/zabbix_agent2.conf" -i -
