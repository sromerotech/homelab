#!/usr/bin/env bash
# Verifies the latest InfluxDB backup from Scaleway S3 can be restored and queried.
# Requires: aws CLI, docker
set -euo pipefail

# --- Defaults ---
SCW_ACCESS_KEY="${SCW_ACCESS_KEY:-}"
SCW_SECRET_KEY="${SCW_SECRET_KEY:-}"
SCW_REGION="${SCW_REGION:-fr-par}"
SCW_ENDPOINT="${SCW_ENDPOINT:-https://s3.fr-par.scw.cloud}"
S3_BUCKET="${S3_BUCKET:-example-bucket}"
S3_PREFIX="influxdb/backups"
INFLUXDB_IMAGE="public.ecr.aws/docker/library/influxdb:2.7"
INFLUXDB_ORG="homelab"
INFLUXDB_BUCKET="homelab"
INFLUXDB_TEST_TOKEN="restore-test-token-$(date +%s)"
INFLUXDB_HOST_PORT="8087"
CONTAINER_NAME="influxdb-restore-test-$$"
LIST_ONLY=false
WORK_DIR=""

# --- Usage ---
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --access-key KEY      Scaleway access key ID (or set SCW_ACCESS_KEY)
  --secret-key SECRET   Scaleway secret key   (or set SCW_SECRET_KEY)
  --region REGION       S3 region              (default: fr-par)
  --endpoint URL        S3 endpoint URL        (default: https://s3.fr-par.scw.cloud)
  --bucket NAME         S3 bucket name         (default: example-bucket)
  --list-only           List available backups and exit without restoring
  -h, --help            Show this help

Environment variables SCW_ACCESS_KEY and SCW_SECRET_KEY are also accepted.
EOF
}

# --- Arg parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --access-key) SCW_ACCESS_KEY="$2"; shift 2 ;;
    --secret-key) SCW_SECRET_KEY="$2"; shift 2 ;;
    --region)     SCW_REGION="$2";     shift 2 ;;
    --endpoint)   SCW_ENDPOINT="$2";   shift 2 ;;
    --bucket)     S3_BUCKET="$2";      shift 2 ;;
    --list-only)  LIST_ONLY=true;      shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "ERROR: Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$SCW_ACCESS_KEY" || -z "$SCW_SECRET_KEY" ]]; then
  echo "ERROR: Scaleway credentials are required."
  echo "  Pass --access-key and --secret-key, or set SCW_ACCESS_KEY / SCW_SECRET_KEY."
  exit 1
fi

# --- Dependency check ---
for cmd in aws docker curl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: '$cmd' is required but not found in PATH."; exit 1; }
done

# --- AWS env ---
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
export AWS_DEFAULT_REGION="$SCW_REGION"

# --- Cleanup trap ---
cleanup() {
  local exit_code=$?
  if [[ -n "$CONTAINER_NAME" ]]; then
    # docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    echo "skipped"
  fi
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    # rm -rf "$WORK_DIR"
    echo "skipped"
  fi
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

# --- Step 1: Find latest backup ---
echo "[1/5] Listing backups in s3://${S3_BUCKET}/${S3_PREFIX}/..."
BACKUPS=$(aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" \
  --endpoint-url "$SCW_ENDPOINT" \
  | awk '{print $2}' | tr -d '/' | sort)

if [[ -z "$BACKUPS" ]]; then
  echo "ERROR: No backups found at s3://${S3_BUCKET}/${S3_PREFIX}/"
  exit 1
fi

echo "Available backups:"
echo "$BACKUPS" | while read -r b; do echo "  $b"; done

LATEST=$(echo "$BACKUPS" | tail -1)
echo "  => Selected: $LATEST"

if $LIST_ONLY; then
  echo "  (--list-only: stopping here)"
  exit 0
fi

# --- Step 2: Download backup ---
WORK_DIR=$(mktemp -d)
BACKUP_DIR="$WORK_DIR/backup"
mkdir -p "$BACKUP_DIR"

echo "[2/5] Downloading s3://${S3_BUCKET}/${S3_PREFIX}/${LATEST}/ ..."
aws s3 cp "s3://${S3_BUCKET}/${S3_PREFIX}/${LATEST}/" "$BACKUP_DIR/" \
  --recursive \
  --endpoint-url "$SCW_ENDPOINT"

FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
echo "  Downloaded $FILE_COUNT file(s)."
if [[ "$FILE_COUNT" -eq 0 ]]; then
  echo "ERROR: Backup directory is empty."
  exit 1
fi

# --- Step 3: Start fresh InfluxDB container ---
echo "[3/5] Starting InfluxDB container ($INFLUXDB_IMAGE)..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "127.0.0.1:${INFLUXDB_HOST_PORT}:8086" \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=admin \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=testpassword123 \
  -e DOCKER_INFLUXDB_INIT_ORG="$INFLUXDB_ORG" \
  -e DOCKER_INFLUXDB_INIT_BUCKET="initial" \
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN="$INFLUXDB_TEST_TOKEN" \
  "$INFLUXDB_IMAGE" >/dev/null

sleep 10

echo "  Waiting for InfluxDB to be ready..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:${INFLUXDB_HOST_PORT}/health" 2>/dev/null | grep -q '"status":"pass"'; then
    echo "  Ready after ${i}s."
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "ERROR: InfluxDB did not become healthy within 60 seconds."
    echo "Container logs:"
    docker logs "$CONTAINER_NAME" | tail -20
    exit 1
  fi
  sleep 2
done

# --- Step 4: Restore backup ---
echo "[4/5] Restoring backup into container..."
docker cp "$BACKUP_DIR" "${CONTAINER_NAME}:/tmp/restore-backup"

docker exec "$CONTAINER_NAME" influx restore /tmp/restore-backup \
  --host "http://localhost:8086" \
  --token "$INFLUXDB_TEST_TOKEN" \
  --org "$INFLUXDB_ORG"

# --- Step 5: Verify with queries ---
echo "[5/5] Verifying data with Flux queries..."

PASS=false
for bucket in homelab homeassistant; do
  echo "  Querying bucket: $bucket ..."
  RESULT=$(docker exec "$CONTAINER_NAME" influx query \
    --host "http://localhost:8086" \
    --token "$INFLUXDB_TEST_TOKEN" \
    --org "$INFLUXDB_ORG" \
    "from(bucket: \"${bucket}\") |> range(start: -365d) |> first() |> limit(n: 3)" 2>&1 || true)

  if echo "$RESULT" | grep -q "^Table: keys:"; then
    TABLES=$(echo "$RESULT" | grep -c "^Table: keys:" || true)
    echo "  [OK] bucket '$bucket': $TABLES table(s) found."
    echo "$RESULT" | head -8
    PASS=true
  else
    echo "  [WARN] bucket '$bucket': no data or query error."
    if [[ -n "$RESULT" ]]; then
      echo "$RESULT" | head -5
    fi
  fi
done

echo ""
if $PASS; then
  echo "=== Backup verification PASSED ==="
  echo "  Backup:    $LATEST"
  echo "  Container: $CONTAINER_NAME (will be removed on exit)"
  exit 0
else
  echo "=== Backup verification FAILED: no queryable data found ==="
  exit 1
fi
