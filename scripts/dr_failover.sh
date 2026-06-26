#!/bin/bash
# ============================================================
# FinCorp RDS Disaster Recovery Failover Script
#
# Performs a full DR failover from the primary RDS instance
# to a restored instance in the DR region.
#
# Usage:
#   ./dr_failover.sh <INSTANCE_ID> <SOURCE_REGION> <DR_REGION>
#
# Or set environment variables before running:
#   export INSTANCE_ID=fincorp-primary-db
#   export SOURCE_REGION=us-east-1
#   export DR_REGION=us-west-2
#   ./dr_failover.sh
# ============================================================
set -euo pipefail

INSTANCE_ID="${1:-${INSTANCE_ID:-}}"
SOURCE_REGION="${2:-${SOURCE_REGION:-us-east-1}}"
DR_REGION="${3:-${DR_REGION:-us-west-2}}"

if [[ -z "$INSTANCE_ID" ]]; then
  echo "ERROR: INSTANCE_ID is required."
  echo "Usage: $0 <INSTANCE_ID> [SOURCE_REGION] [DR_REGION]"
  exit 1
fi

DR_INSTANCE_ID="${INSTANCE_ID}-dr-restored"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
SNAPSHOT_ID="${INSTANCE_ID}-manual-${TIMESTAMP}"
DR_SNAPSHOT_ID="${SNAPSHOT_ID}-copy"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ============================================================
# STEP 1: Trigger manual backup (RDS snapshot) and wait
# ============================================================
log "STEP 1: Creating manual RDS snapshot '${SNAPSHOT_ID}' in ${SOURCE_REGION}..."

aws rds create-db-snapshot \
  --db-instance-identifier "$INSTANCE_ID" \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --region "$SOURCE_REGION" \
  --output text > /dev/null

log "Waiting for snapshot to become available..."
while true; do
  STATUS=$(aws rds describe-db-snapshots \
    --db-snapshot-identifier "$SNAPSHOT_ID" \
    --region "$SOURCE_REGION" \
    --query "DBSnapshots[0].Status" \
    --output text)
  log "  Snapshot status: ${STATUS}"
  if [[ "$STATUS" == "available" ]]; then
    break
  fi
  sleep 30
done
log "STEP 1 COMPLETE: Snapshot is available."

# ============================================================
# STEP 2: Get recovery point ARN
# ============================================================
log "STEP 2: Retrieving snapshot ARN from ${SOURCE_REGION}..."

SNAPSHOT_ARN=$(aws rds describe-db-snapshots \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --region "$SOURCE_REGION" \
  --query "DBSnapshots[0].DBSnapshotArn" \
  --output text)

log "STEP 2 COMPLETE: Recovery point ARN = ${SNAPSHOT_ARN}"

# ============================================================
# STEP 3: Copy snapshot to DR region and wait
# ============================================================
log "STEP 3: Copying snapshot to DR region ${DR_REGION} as '${DR_SNAPSHOT_ID}'..."

aws rds copy-db-snapshot \
  --source-db-snapshot-identifier "$SNAPSHOT_ARN" \
  --target-db-snapshot-identifier "$DR_SNAPSHOT_ID" \
  --region "$DR_REGION" \
  --output text > /dev/null

log "Waiting for DR snapshot copy to become available..."
while true; do
  STATUS=$(aws rds describe-db-snapshots \
    --db-snapshot-identifier "$DR_SNAPSHOT_ID" \
    --region "$DR_REGION" \
    --query "DBSnapshots[0].Status" \
    --output text)
  log "  DR snapshot status: ${STATUS}"
  if [[ "$STATUS" == "available" ]]; then
    break
  fi
  sleep 30
done
log "STEP 3 COMPLETE: DR snapshot is available in ${DR_REGION}."

# ============================================================
# STEP 4: Delete primary DB (simulate primary region failure)
# ============================================================
log "STEP 4: Simulating primary region failure — deleting '${INSTANCE_ID}' in ${SOURCE_REGION}..."
log "WARNING: This is destructive. Proceeding in 5 seconds..."
sleep 5

aws rds delete-db-instance \
  --db-instance-identifier "$INSTANCE_ID" \
  --skip-final-snapshot \
  --region "$SOURCE_REGION" \
  --output text > /dev/null

log "Waiting for primary instance to be deleted..."
while true; do
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --region "$SOURCE_REGION" \
    --query "DBInstances[0].DBInstanceStatus" \
    --output text 2>/dev/null || echo "deleted")
  log "  Primary instance status: ${STATUS}"
  if [[ "$STATUS" == "deleted" ]]; then
    break
  fi
  sleep 30
done
log "STEP 4 COMPLETE: Primary instance deleted."

# ============================================================
# STEP 5: Restore from snapshot in DR region
# ============================================================
log "STEP 5: Restoring '${DR_INSTANCE_ID}' from snapshot in ${DR_REGION}..."

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "$DR_INSTANCE_ID" \
  --db-snapshot-identifier "$DR_SNAPSHOT_ID" \
  --db-instance-class "db.t3.micro" \
  --no-publicly-accessible \
  --region "$DR_REGION" \
  --output text > /dev/null

log "STEP 5 COMPLETE: Restore initiated."

# ============================================================
# STEP 6: Wait for restored instance and print endpoint
# ============================================================
log "STEP 6: Waiting for restored instance '${DR_INSTANCE_ID}' to become available..."

while true; do
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$DR_INSTANCE_ID" \
    --region "$DR_REGION" \
    --query "DBInstances[0].DBInstanceStatus" \
    --output text)
  log "  DR instance status: ${STATUS}"
  if [[ "$STATUS" == "available" ]]; then
    break
  fi
  sleep 30
done

DR_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DR_INSTANCE_ID" \
  --region "$DR_REGION" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

log "============================================================"
log "DR FAILOVER COMPLETE"
log "Restored instance : ${DR_INSTANCE_ID}"
log "DR region         : ${DR_REGION}"
log "Endpoint          : ${DR_ENDPOINT}"
log "============================================================"
log "Update your application connection string to point to the new endpoint."
