# Zabbix Scripts Collection

All scripts require a proper configuration of `/etc/zabbix/zabbix_agent2.conf` to function.

## Zabbix agent


## Zabbix agent (active)


## Zabbix trapper

One-shot updates that are sent to Zabbix for monitoring. Reduces technical depth and improves performance for tasks that don't require periodic checks. Ideal for small and weak Zabbix servers to keep the monthly cost down.

**General dependencies:**
- zabbix_sender

### - borgmatic

Checks backup status and collects repository statistics.

**Dependencies:**
- borgmatic
- jq (to parse repository statistics)

**Usage:** Register as callback in borgmatic. See [`borgmatic.sh`](./sender_scripts/borgmatic.sh) for usage examples.

**Macros:**
- `{$BORGMATIC_LAST_BACKUP_MAX_AGE}`: Max allowed age in seconds for successful backups (defaults to 1 day).

If borgmatic doesn't run or otherwise fails to execute the script, you will still receive a trigger warning when the max allowed backup age is exceeded. This works by having an item of type `CALCULATED` that updates periodically. Run the script at least once with the `done` argument to populate the item values.

### - YUM Updates

Checks for available updates using `yum check-update`. Never miss out on important updates. Ideal when you have many servers that require regular maintenance and updates.

**Dependencies:**
- yum

**Usage:** Install as cron job with your preferred schedule.
