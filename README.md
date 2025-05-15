# Zabbix Scripts Collection

All scripts require a proper configuration of `/etc/zabbix/zabbix_agent2.conf` to function.

## Zabbix agent


## Zabbix agent (active)


## Zabbix trapper

One-shot updates that are sent to Zabbix for monitoring. Reduces technical depth and improves performance for tasks that don't require periodic checks. Ideal for small and weak Zabbix servers to keep the monthly cost down.

**General dependencies:**
- zabbix_sender

<details>
<summary>Templates</summary>

### borgmatic

Checks backup status and collects repository statistics.

<details>
<summary>borgmatic</summary>

**Dependencies:**
- borgmatic
- jq (to parse repository statistics)

**Usage:** Register as callback in borgmatic. See [`borgmatic.sh`](./sender_scripts/borgmatic.sh) for usage examples.

**Macros:**
- `{$BORGMATIC_LAST_BACKUP_MAX_AGE}`: Max allowed age in seconds for successful backups (defaults to 1 day).

If borgmatic doesn't run or otherwise fails to execute the script, you will still receive a trigger warning when the max allowed backup age is exceeded. This works by having an item of type `CALCULATED` that updates periodically. Run the script at least once with the `done` argument to populate the item values.

</details>

### YUM Updates

Checks for available updates using `yum check-update`. Never miss out on important updates. Ideal when you have many servers that require regular maintenance and updates.

<details>
<summary>YUM Updates</summary>

**Dependencies:**
- yum

**Usage:** Install as cron job with your preferred schedule.

</details>

</details>

## Templates

Modified official and built-in Zabbix templates.

<details>
<summary>Templates</summary>

### Nextcloud by HTTP

Monitor Nextcloud without sacrificing security.

The built-in template wants you to configure an admin account with full read-write system access. 🤢

**Differences:**
- Uses the access token feature (`NC-Token`) of the `serverinfo` app to allow safe read-only access to the monitoring interface.
- User discovery and user monitoring is **disabled** because no safe read-only access to the required endpoint is available. See [nextcloud/server#26233](https://github.com/nextcloud/server/issues/26233) and [nextcloud/limit_login_to_ip#20](https://github.com/nextcloud/limit_login_to_ip/issues/20) for reference.
- Added Nextcloud server and apps update monitoring.
  - Checks if Nextcloud server updates are available.
  - Checks the number of apps that can be updated.
- Disabled some redundant items that clash with OS templates to avoid double monitoring.

</details>
