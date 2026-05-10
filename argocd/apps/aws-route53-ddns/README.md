# route53-ddns

CronJob that keeps the VPN hostname pointing at the home network's current public WAN IP by UPSERTing an AWS Route 53 A record every 5 minutes.

## How it works

1. Fetches the public IP from `checkip.amazonaws.com` (falls back to `api.ipify.org`).
2. Reads the current A record value directly from Route 53 (no local state).
3. If the IP changed, issues a `ChangeResourceRecordSets` UPSERT. Otherwise, exits quietly.

## Pre-deploy: create the Secret out-of-band

The Secret is never committed to git. Create it directly on the cluster:

```bash
kubectl create namespace aws-scripts --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic aws-credentials \
  --namespace aws-scripts \
  --from-literal=AWS_ACCESS_KEY_ID='AKIAIOSFODNN7EXAMPLE' \
  --from-literal=AWS_SECRET_ACCESS_KEY='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' \
  --from-literal=HOSTED_ZONE_ID='Z1234567890ABC' \
  --from-literal=RECORD_NAME='foo.bar.com'
```

The IAM user needs only:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["route53:ListResourceRecordSets", "route53:ChangeResourceRecordSets"],
      "Resource": "arn:aws:route53:::hostedzone/<ZONE_ID>"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZones",
      "Resource": "*"
    }
  ]
}
```

## Deploy

ArgoCD auto-discovers the app on push. The Secret must exist before the CronJob's first run or the pod will fail to start.

```bash
git add argocd/apps/route53-ddns/
git commit -m "feat: route53-ddns cronjob"
git push
```

## Test manually

Trigger a one-off Job from the CronJob spec without waiting for the schedule:

```bash
kubectl create job --from=cronjob/route53-ddns ddns-test -n aws-scripts
```

Watch it run:

```bash
kubectl get jobs -n aws-scripts -w
```

## Inspect logs

```bash
# Most recent completed pod
kubectl logs -n aws-scripts -l app=route53-ddns --tail=50

# Or target a specific job pod
kubectl get pods -n aws-scripts
kubectl logs -n aws-scripts <pod-name>
```

Expected output when IP is already correct:
```
[INFO] Public IP: 1.2.3.4
[INFO] Route 53 current value: 1.2.3.4
[INFO] No change needed.
```

Expected output when an update is made:
```
[INFO] Public IP: 1.2.3.5
[INFO] Route 53 current value: 1.2.3.4
[INFO] Updated <record>: 1.2.3.4 -> 1.2.3.5
```
