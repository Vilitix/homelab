#!/usr/bin/env bash
# Restore the most recent OpenPaper checkout backup and restart it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

BACKUP="$(ls -dt "$ROOT"/openpaper.bak.* 2>/dev/null | head -1 || true)"
if [ -z "$BACKUP" ]; then
  echo "No openpaper.bak.* directory found; nothing to roll back to." >&2
  exit 1
fi

echo "Rolling back to: $BACKUP"

docker compose stop \
  openpaper-server \
  openpaper-jobs-api \
  openpaper-jobs-worker \
  openpaper-jobs-beat \
  openpaper-client >/dev/null 2>&1 || true

if [ -d "$ROOT/openpaper" ]; then
  FAILED="$ROOT/openpaper.failed.$(date +%Y%m%d%H%M%S)"
  mv "$ROOT/openpaper" "$FAILED"
  echo "Failed checkout kept at: $FAILED"
fi

mv "$BACKUP" "$ROOT/openpaper"

docker compose build openpaper-server openpaper-jobs-api openpaper-client
docker compose up -d --force-recreate \
  openpaper-migrate \
  openpaper-server \
  openpaper-jobs-api \
  openpaper-jobs-worker \
  openpaper-jobs-beat \
  openpaper-client

echo "Rollback complete."
