#!/bin/sh

# Usage:
#
# before_backup:
#   - borgmatic.sh start
# after_backup:
#   - borgmatic.sh done
# on_error:
#   - borgmatic.sh fail
#
# manual statistic collection: (does not affect backup validity monitoring)
# - borgmatic.sh collect

export LANG=C
export LANGUAGE=

BORG_ACTION="$1"
BORG_TIMESTAMP="$(date -u +%s)"

# build the stream for zabbix sender
ZBX_STREAM=""
ZBX_STREAM+="- borgmatic.last.action.type ${BORG_ACTION}\n"
ZBX_STREAM+="- borgmatic.last.action.timestamp ${BORG_TIMESTAMP}\n"

function extract_borg_stats() {
    local BORG_INFO="$(borgmatic info --archive latest --json)"

    # extract values using jq
    local DURATION="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].duration')"                     # duration of backup in seconds
    local NUM_FILES="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].stats.nfiles')"                # number of files (this archive)
    local COMPRESSED_SIZE="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].stats.compressed_size')" # compressed size (this archive)
    local ORIGINAL_SIZE="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].stats.original_size')"     # original size (this archive)
    local DEDUP_SIZE="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].stats.deduplicated_size')"    # deduplicated size (this archive)
    #local START_TIME="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].start')"                     # start of backup
    #local END_TIME="$(echo "$BORG_INFO" | jq -r '.[0].archives[0].end')"                         # end of backup
    local TOTAL_CHUNKS="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.total_chunks')"             # total chunks (all archives)
    local TOTAL_CSIZE="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.total_csize')"               # total compressed size (all archives)
    local TOTAL_SIZE="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.total_size')"                 # total original size (all archives)
    local UNIQUE_CHUNKS="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.total_unique_chunks')"     # total unique chunks (all archives)
    local UNIQUE_CSIZE="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.unique_csize')"             # deduplicated compressed size (all archives)
    local UNIQUE_SIZE="$(echo "$BORG_INFO" | jq -r '.[0].cache.stats.unique_size')"               # deduplicated size (all archives)

    # add all values to ZBX_STREAM
    ZBX_STREAM+="- borgmatic.last.backup.duration ${DURATION}\n"
    ZBX_STREAM+="- borgmatic.last.backup.files ${NUM_FILES}\n"
    ZBX_STREAM+="- borgmatic.last.backup.compressed_size ${COMPRESSED_SIZE}\n"
    ZBX_STREAM+="- borgmatic.last.backup.original_size ${ORIGINAL_SIZE}\n"
    ZBX_STREAM+="- borgmatic.last.backup.deduplicated_size ${DEDUP_SIZE}\n"
    ZBX_STREAM+="- borgmatic.total.chunks ${TOTAL_CHUNKS}\n"
    ZBX_STREAM+="- borgmatic.total.compressed_size ${TOTAL_CSIZE}\n"
    ZBX_STREAM+="- borgmatic.total.original_size ${TOTAL_SIZE}\n"
    ZBX_STREAM+="- borgmatic.total.unique_chunks ${UNIQUE_CHUNKS}\n"
    ZBX_STREAM+="- borgmatic.total.unique_compressed_size ${UNIQUE_CSIZE}\n"
    ZBX_STREAM+="- borgmatic.total.unique_size ${UNIQUE_SIZE}\n"
}

case "$BORG_ACTION" in
    done)
        ZBX_STREAM+="- borgmatic.last.backup.complete 1\n"
        ZBX_STREAM+="- borgmatic.last.backup.timestamp ${BORG_TIMESTAMP}\n"

        # extract and append latest repository statistics for graph building
        extract_borg_stats
        ;;
    fail)
        ZBX_STREAM+="- borgmatic.last.backup.complete 0\n"
        ;;
    collect)
        # extract and append latest repository statistics for graph building
        extract_borg_stats
        ;;
esac

echo -en "${ZBX_STREAM}" | zabbix_sender -c "/etc/zabbix/zabbix_agent2.conf" -i -
