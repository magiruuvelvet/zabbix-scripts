#!/bin/sh

# NOTES:
#  - If you are on Rocky Linux, install the `yum-utils` compatibility package.

export LANG=C
export LANGUAGE=

needs_restarting_bin="/usr/bin/needs-restarting"

count_lines() {
  if [ -z "$1" ]; then
    # counting doesn't work correctly if the variable is empty
    echo -n "0"
  else
    # count actual lines regardless of line ending (or lack thereof)
    echo -n "$(printf "%s_" "$1" | grep -c "^")"
  fi
}

# ensure the package cache is up-to-date
yum -q makecache

# obtain a list of available package updates with their new version
YUM_UPDATES_DETAILS="$(yum check-update | tail -n +3 | awk '{print $1 "=" $2}')"
YUM_UPDATES_COUNT="$(count_lines "${YUM_UPDATES_DETAILS}")"

YUM_NEEDS_RESTARTING_REBOOTHINT_DETAILS="$("$needs_restarting_bin" -r)"
YUM_NEEDS_RESTARTING_REBOOTHINT_STATUS="$?"

YUM_NEEDS_RESTARTING_SERVICES_DETAILS="$("$needs_restarting_bin" -s)"
YUM_NEEDS_RESTARTING_SERVICES_COUNT="$(count_lines "${YUM_NEEDS_RESTARTING_SERVICES_DETAILS}")"

# send the timestamp of the last update check for reliability monitoring
# get informed immediately when update checks stop working
YUM_STATS_TIMESTAMP="$(date -u +%s)"

# build the stream for zabbix sender
ZBX_STREAM=""
ZBX_STREAM+="- yum.packagestoupdate.count ${YUM_UPDATES_COUNT}\n"
ZBX_STREAM+="- yum.packagestoupdate.details \"$(echo "${YUM_UPDATES_DETAILS}" | tr "\n" " " | xargs)\"\n"
ZBX_STREAM+="- yum.system.needs_restarting.reboothint.status ${YUM_NEEDS_RESTARTING_REBOOTHINT_STATUS}\n"
ZBX_STREAM+="- yum.system.needs_restarting.services.count ${YUM_NEEDS_RESTARTING_SERVICES_COUNT}\n"
ZBX_STREAM+="- yum.stats.timestamp.last_update_check ${YUM_STATS_TIMESTAMP}\n"

echo -en "${ZBX_STREAM}" | zabbix_sender -c "/etc/zabbix/zabbix_agent2.conf" -i -
