# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

GitOps configuration for a personal k3s homelab cluster. ArgoCD continuously reconciles everything in `argocd/` against the cluster. Pushing to `main` is the deployment mechanism.

## Adding a new app

Create a directory under `argocd/apps/<app-name>/` with an `application.yaml`. ArgoCD's ApplicationSet in `argocd/selfconfig/appsets/applicationSet.yaml` auto-discovers any directory matching `argocd/apps/*` and deploys it. No manual registration needed after that.

Two patterns are used:

**Helm wrapper** (grafana, influxdb): create a `chart/` subdirectory with `Chart.yaml` (declaring an upstream dependency), `values.yaml`, and optionally `secrets.yaml`. The `application.yaml` points to the `chart/` path and references `secrets://secrets.yaml` for encrypted values.

**Kustomize** (home-assistant): create a `manifests/` subdirectory with raw Kubernetes manifests and a `kustomization.yaml`. The `application.yaml` uses `kustomize:` for image/patch overrides.

## Secrets management (SOPS + age)

Secrets live in `secrets.yaml` files co-located with charts. The `.sops.yaml` at repo root configures encryption:
- Files matching `.*/secrets\.yaml$` are encrypted
- Only fields matching `^(password|token|adminPassword)$` are encrypted (rest stays plaintext)
- Encryption uses age key: `age1husckuuhq6mdvz036xrs2rgrl04hdqyvu7emt5jcph5hfae3fessdc92mk`

To encrypt a new `secrets.yaml`:
```bash
sops --encrypt --in-place argocd/apps/<app>/chart/secrets.yaml
```

To edit an existing encrypted file:
```bash
sops argocd/apps/<app>/chart/secrets.yaml
```

ArgoCD's repoServer has the helm-secrets plugin + SOPS + age private key pre-installed (via init container in `servers/k3s/manifests/argocd.HelmChart.yaml`). The age private key must exist as a Kubernetes secret `helm-secrets-private-keys` in the `argocd` namespace before ArgoCD can decrypt.

## Bootstrap sequence (first-time cluster setup)

1. k3s applies `servers/k3s/manifests/argocd.HelmChart.yaml` automatically — this installs ArgoCD with helm-secrets support.
2. Create the repository credential secret and repository manifest (see `argocd/README.md`).
3. Create the age private key secret: `kubectl create secret generic helm-secrets-private-keys --from-file=key.txt=<age-private-key-file> -n argocd`
4. Manually apply the root ApplicationSet: `kubectl apply -f argocd/applicationSet.yaml`

After step 4, ArgoCD manages itself via `argocd/selfconfig/` and all apps via `argocd/apps/`.

## ArgoCD two-tier self-management

- `argocd/applicationSet.yaml` — bootstrapped manually; creates the `argocd-selfconfig` Application that watches `argocd/selfconfig/`
- `argocd/selfconfig/` — ArgoCD's own config (projects, repo credentials, the auto-discovery ApplicationSet); syncs with `prune: true, selfHeal: true`
- `argocd/selfconfig/appsets/applicationSet.yaml` — auto-discovers `argocd/apps/*`; deploys with `prune: false, selfHeal: false`

## App-specific notes

**Home Assistant** (`namespace: home-automation`):
- HA config files (configuration.yaml, Lovelace dashboard, automations) are stored as ConfigMaps and mounted into the container.
- Image version is patched in `application.yaml` under `kustomize.images`.
- Requires a manually created secret `home-assistant-influxdb` with key `INFLUXDB_TOKEN` in the `home-automation` namespace.
- Passes through the Zigbee USB stick at `/dev/ttyACM0` via a `hostPath` volume (requires `privileged: true`).

**Grafana** (`namespace: monitoring`):
- Reads InfluxDB admin token from the secret `influxdb-influxdb2-auth` (created by the InfluxDB chart) as env var `INFLUXDB_TOKEN`.
- InfluxDB datasource is provisioned automatically via `values.yaml`.
- Dashboards are provisioned via ConfigMaps labelled `grafana_dashboard: "1"`.

**InfluxDB** (`namespace: monitoring`):
- Organization: `homelab`, default bucket: `homelab`, also creates `homeassistant` bucket (referenced by Grafana).
- Backup CronJob and init bucket Job are in `argocd/apps/influxdb/chart/templates/`.
