# cloudflare-ddns

CronJob that keeps the VPN hostname pointing at the home network's current public WAN IP by
creating/updating a Cloudflare A record every 30 minutes.

This is the Cloudflare counterpart of `aws-route53-ddns`. Use it once the domain's NS records
point at Cloudflare (Cloudflare is authoritative for DNS).

## How it works

1. Fetches the public IP from `checkip.amazonaws.com` (falls back to `api.ipify.org`).
2. Reads the current A record value directly from the Cloudflare API (no local state).
3. If the record is **missing**, it is created (POST). If it exists and the IP changed, it is
   updated (PUT). If the IP already matches, it exits quietly.

The A record is written with `proxied: false` (raw IP, correct for VPN / non-HTTP use).

## Pre-deploy: create the Secret out-of-band

The Secret is never committed to git. Create it directly on the cluster:

```bash
kubectl create namespace cloudflare-ddns --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic cloudflare-credentials \
  --namespace cloudflare-ddns \
  --from-literal=CF_API_TOKEN='<cloudflare-api-token>' \
  --from-literal=ZONE_ID='<zone-id>' \
  --from-literal=RECORD_NAME='vpn.example.com'
```

- `CF_API_TOKEN` — a scoped API token (Cloudflare dashboard → My Profile → API Tokens).
  Permissions: **Zone → DNS → Edit** (and Zone → Zone → Read) restricted to the target zone.
- `ZONE_ID` — found on the zone's Overview page in the Cloudflare dashboard.
- `RECORD_NAME` — the full record name, e.g. `vpn.example.com`.

## Deploy

ArgoCD auto-discovers the app on push. The Secret must exist before the CronJob's first run or
the pod will fail to start.

```bash
git add argocd/apps/cloudflare-ddns/
git commit -m "feat: cloudflare-ddns cronjob"
git push
```

## Test manually

Trigger a one-off Job from the CronJob spec without waiting for the schedule:

```bash
kubectl create job --from=cronjob/cloudflare-ddns cf-ddns-test -n cloudflare-ddns
```

Watch it run:

```bash
kubectl get jobs -n cloudflare-ddns -w
```

## Inspect logs

```bash
# Most recent completed pod
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns --tail=50

# Or target a specific job pod
kubectl get pods -n cloudflare-ddns
kubectl logs -n cloudflare-ddns <pod-name>
```

Expected output when the IP is already correct:
```
[INFO] Public IP: 1.2.3.4
[INFO] Cloudflare current value: 1.2.3.4
[INFO] No change needed.
```

Expected output when an update (or first-time create) is made:
```
[INFO] Public IP: 1.2.3.5
[INFO] Cloudflare current value: 1.2.3.4
[INFO] Updated vpn.example.com: 1.2.3.4 -> 1.2.3.5
```
