# influxdb

InfluxDB 2.x deployed via Helm with a daily backup CronJob that writes to Scaleway Object Storage.

## Scaleway Object Storage access model

Scaleway uses a **two-layer access control model** that is different from AWS:

| Layer | Where configured | What it controls |
|---|---|---|
| IAM policy | Scaleway console → IAM → Applications | Whether the principal can perform Object Storage operations at all |
| Bucket policy | Scaleway console → Object Storage → Bucket settings | Which specific buckets/objects the principal can access |

**Both layers must allow the action.** A bucket policy alone is not enough — unlike AWS S3, where a bucket policy grants same-account access without an IAM policy. If IAM does not grant the capability, every S3 request returns `AccessDenied` regardless of the bucket policy.

### Setup used for the backup CronJob

1. **IAM**: create a policy with permissions `ObjectStorageObjectsDelete`, `ObjectStorageObjectsRead`, `ObjectStorageObjectsWrite` and attach it to the Scaleway IAM application whose API key the CronJob uses. This is the broad capability grant.

   Policy naming convention: `<project>.<principal>.<system>.<permissions>` — e.g. `Home.homelab.Storage.rwd`

2. **Bucket policy**: apply the following policy to the backup bucket to scope access to that application only.

   Bucket naming convention: `<bucket-id>.<permissions>` — e.g. `sromerotech-homelab-influxdb.rwd`

```json
{
  "Version": "2023-04-17",
  "Id": "<bucket-name>.rwd",
  "Statement": [
    {
      "Sid": "backup-app",
      "Effect": "Allow",
      "Principal": {
        "SCW": "application_id:<your-application-id>"
      },
      "Action": "*",
      "Resource": [
        "<bucket-name>",
        "<bucket-name>/*"
      ]
    },
    {
      "Sid": "Scaleway secure statement",
      "Effect": "Allow",
      "Principal": {
        "SCW": "user_id:<your-user-id>"
      },
      "Action": "*",
      "Resource": [
        "<bucket-name>",
        "<bucket-name>/*"
      ]
    }
  ]
}
```

Note: Scaleway's policy `Version` is `"2023-04-17"`, not AWS's `"2012-10-17"`. The S3 endpoint for the Paris region is `https://s3.fr-par.scw.cloud`.

### Verify access

```bash
AWS_ACCESS_KEY_ID=<key> AWS_SECRET_ACCESS_KEY=<secret> \
  aws s3 ls s3://<bucket-name>/ \
  --endpoint-url https://s3.fr-par.scw.cloud
```

## Pre-deploy: create secrets out-of-band

The following secrets must exist before ArgoCD syncs. They are never committed to git.

**InfluxDB admin credentials** (created by the Helm chart from `secrets.yaml`):

```bash
# Managed by SOPS — edit via:
sops argocd/apps/influxdb/chart/secrets.yaml
```

**Scaleway S3 credentials for the backup CronJob:**

```bash
kubectl create secret generic scaleway-app.homelab \
  --namespace monitoring \
  --from-literal=access-key-id='<SCW_ACCESS_KEY>' \
  --from-literal=secret-access-key='<SCW_SECRET_KEY>' \
  --from-literal=region='fr-par' \
  --from-literal=endpoint='https://s3.fr-par.scw.cloud' \
  --from-literal=bucket='<bucket-name>'
```

**InfluxDB token for Home Assistant:**

```bash
kubectl create secret generic home-assistant-influxdb \
  --namespace home-automation \
  --from-literal=INFLUXDB_TOKEN='<token>'
```

## Test backup manually

Trigger a one-off Job from the CronJob spec:

```bash
kubectl create job --from=cronjob/influxdb-backup influxdb-backup-test -n monitoring
```

Watch it:

```bash
kubectl get jobs -n monitoring -w
kubectl logs -n monitoring -l app=influxdb-backup --tail=50
```

New backups land under `s3://<bucket-name>/influxdb/backups/daily/<timestamp>/`.

## Retention

The backup CronJob writes two independent, differently-shaped backups so recent data is cheaply restorable while full history is never lost:

- **Daily** (`influxdb/backups/daily/<timestamp>/`): a full binary `influx backup` snapshot of the whole instance, kept for `BACKUP_RETENTION_DAYS` (30) days then deleted. Restore with `influx restore` — this is the fast, exact path for recovering from something that happened recently.
- **Quarterly** (`influxdb/backups/quarterly/<YYYY>-Q<N>/<bucket>.csv.gz`): every day, a read-only Flux query (`from(bucket: "...") |> range(start: <start of current quarter>)`) exports each bucket's quarter-to-date data as annotated CSV, gzipped, and uploaded to a fixed key for that bucket+quarter. Uploading to the same key each day simply overwrites the previous day's file, so there's never more than one object per bucket per quarter — no separate cleanup step needed. Once the calendar quarter changes, the CronJob starts writing to a new key, so the previous quarter's last-written file is never touched again and becomes that quarter's permanent historic record.

This export never writes to or deletes anything in production — it's a plain query. It's also why the `homeassistant` bucket's data (which InfluxDB itself expires after `4380h` / ~6 months, per `init-bucket-job.yaml`) doesn't get lost: it's captured into the quarterly export the same day it's written, long before InfluxDB's own retention would prune it.

Restoring a quarterly archive: `gunzip` the file, then `influx write --bucket <target> --org homelab --token <token> --format csv --file <file> --host <host>`.

The CSV format is also the more useful one for the eventual move to a more powerful (e.g. cloud-backed) analytics system — it's directly readable by standard tooling without needing an InfluxDB instance to unpack it first.

Backups created before this tiering was introduced live under the old flat `influxdb/backups/<timestamp>/` prefix. They are not touched, deleted, or reorganized by the current script — they're legacy and can be migrated manually if desired.
