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
kubectl create secret generic scaleway-app \
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
