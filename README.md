# Zabbix Scripts Collection

All scripts require a proper configuration of `/etc/zabbix/zabbix_agent2.conf` to function.

## Zabbix agent

### -----\[ check mountpoint \]-----

Checks if the given directory is a mount point or not.

**Usage:** `directory.is_mountpoint[/path/to/mount]`

## Zabbix trapper

One-shot updates that are sent to Zabbix for monitoring. Reduces technical depth and improves performance for tasks that don't require periodic checks. Ideal for small and weak Zabbix servers to keep the monthly cost down.

**General dependencies:**
- zabbix_sender

### -----\[ borgmatic \]-----

Checks backup status and collects repository statistics.

**Dependencies:**
- borgmatic
- jq (to parse repository statistics)

**Usage:** Register as callback in borgmatic. See [`borgmatic.sh`](./sender_scripts/borgmatic.sh) for usage examples.

**Macros:**
- `{$BORGMATIC_LAST_BACKUP_MAX_AGE}`: Max allowed age in seconds for successful backups (defaults to 1 day).

> [!Note]
> If borgmatic doesn't run or otherwise fails to execute the script, you will still receive a trigger warning when the max allowed backup age is exceeded. This works by having an item of type `CALCULATED` that updates periodically. Run the script at least once with the `done` argument to populate the item values.

### -----\[ YUM Updates \]-----

Checks for available updates using `yum check-update`. Never miss out on important updates. Ideal when you have many servers that require regular maintenance and updates.

**Dependencies:**
- yum

**Usage:** Install as cron job with your preferred schedule.

## Zabbix templates

Modified official and built-in Zabbix templates.

### -----\[ Nextcloud by HTTP \]-----

Monitor Nextcloud without sacrificing security.

The built-in template wants you to configure an admin account with full read-write system access. 🤢

**Differences:**
- Uses the access token feature (`NC-Token`) of the `serverinfo` app to allow safe read-only access to the monitoring interface.
- User discovery and user monitoring is **disabled** because no safe read-only access to the required endpoint is available. See [nextcloud/server#26233](https://github.com/nextcloud/server/issues/26233) and [nextcloud/limit_login_to_ip#20](https://github.com/nextcloud/limit_login_to_ip/issues/20) for reference.
- Added Nextcloud server and apps update monitoring.
  - Checks if Nextcloud server updates are available.
  - Checks the number of apps that can be updated.
- Disabled some redundant items that clash with OS templates to avoid double monitoring.

## Custom templates

### -----\[ OpenBao Seal Status ]\-----

Monitors the availability of Vault secrets.

This simple template can be added to virtual hosts without any monitoring interfaces. All checks are performed on the Zabbix server (or proxy).

Create monitoring credentials to monitor secret value retrieval:\
`bao kv put -mount=secret zabbix/openbao-status expected-value=openbao-alive`

### -----\[ Git Release Monitor ]\-----

Monitors Git repositories for new latest stable releases.

Useful for applications that either don't have any update checker mechanism built-in or the update checker mechanism is poorly implemented. This monitoring approach depends on upstream doing proper application release maintenance (not repository tags).

Examples of poor update checker mechanisms:
- API: can't be reached from a JSON or XML API because the developer wants you to access the update page in the web browser, or uses a custom built-in notification system.
- ACL: requires privileged admin tokens with full read-write system access because the application lacks token scopes or other access mechanisms with minimal read-only permissions. extremely common in personal single-user applications.

**Supported Providers:**
- GitHub (Macro: `GITHUB`)
- Codeberg (Macro: `CODEBERG`)

**Macros:**
- `{$GIT_RELEASE_MONITOR.*.REPO_LIST}`: Comma-separated list of repositories (username/repo-name) to monitor.

**Notes:**
- Uses the API of the corresponding provider to monitor releases.

### -----\[ Vaultwarden ]\-----

Minimal Vaultwarden health check template with release monitoring.

> [!Note]
> To monitor releases and get update alerts add the **Git Release Monitor** template to your host and add `dani-garcia/vaultwarden` to the GitHub repository list macro.

**Macros:**
- `{$VAULTWARDEN.URL}`: The absolute URL to the Vaultwarden server. Must be reachable from the Zabbix server/proxy that hosts this template.
- `{$VAULTWARDEN.ALIVE_MAX_AGE}`: Max allowed age in seconds for successful alive heartbeats.
