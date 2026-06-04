---
description: Download the latest InfluxDB backup from Scaleway S3 and verify it restores and queries successfully. Use when asked to test, verify, or validate the InfluxDB backup.
argument-hint: "[--list-only]"
disable-model-invocation: true
allowed-tools: Bash
---

## Your Task

Run the bundled script to verify the latest InfluxDB backup is restorable.

First check whether Scaleway credentials are available:

```bash
echo "SCW_ACCESS_KEY set: ${SCW_ACCESS_KEY:+yes}${SCW_ACCESS_KEY:-no}"
echo "SCW_SECRET_KEY set: ${SCW_SECRET_KEY:+yes}${SCW_SECRET_KEY:-no}"
```

If both are set, run the script, passing any arguments the user provided (`$ARGUMENTS`):

```bash
bash ${CLAUDE_SKILL_DIR}/verify-influxdb-backup.sh $ARGUMENTS
```

If credentials are missing, tell the user:

> `SCW_ACCESS_KEY` and `SCW_SECRET_KEY` must be set in your environment, or pass them directly:
> ```
> /verify-influxdb-backup --access-key KEY --secret-key SECRET
> ```

## What the script does

1. Lists backups in `s3://sromerotech-homelab-influxdb/influxdb/backups/` — picks the latest
2. Downloads it locally to a temp directory
3. Starts a fresh `influxdb:2.7` Docker container (port 8087)
4. Restores the backup with `influx restore --org homelab`
5. Queries the `homelab` and `homeassistant` buckets, confirms data exists
6. Cleans up the container and temp files on exit

Exits 0 on success (`=== Backup verification PASSED ===`) or 1 on any failure.

Pass `--list-only` to list available backups without running Docker.
