#!/usr/bin/env bash
# Update the OpenPaper checkout to the latest upstream, reapply local changes,
# rebuild, migrate, and restart the OpenPaper services.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHECKOUT="$ROOT/openpaper"
UPSTREAM="https://github.com/khoj-ai/openpaper.git"
TMP="$(mktemp -d)"
ROLLBACK_READY=0

cleanup() {
  status=$?
  rm -rf "$TMP"
  if [ "$status" -ne 0 ] && [ "$ROLLBACK_READY" = "1" ]; then
    ROLLBACK_READY=0
    echo
    echo "Update failed; rolling back automatically..."
    "$ROOT/openpaper-rollback.sh" || true
  fi
}
trap cleanup EXIT

cd "$ROOT"

if [ "${FORCE_UPDATE:-0}" != "1" ] && [ -d "$CHECKOUT/.git" ]; then
  REMOTE_HEAD="$(git ls-remote "$UPSTREAM" HEAD 2>/dev/null | awk '{print $1}' || true)"
  LOCAL_HEAD="$(git -C "$CHECKOUT" rev-parse HEAD 2>/dev/null || true)"
  if [ -n "$REMOTE_HEAD" ] && [ "$REMOTE_HEAD" = "$LOCAL_HEAD" ]; then
    echo "OpenPaper is already up to date ($LOCAL_HEAD). Set FORCE_UPDATE=1 to rebuild anyway."
    exit 0
  fi
fi

DB_BACKUP="$ROOT/openpaper-db-backup.$(date +%Y%m%d%H%M%S).dump"
echo "Backing up Postgres to $DB_BACKUP"
docker compose exec -T openpaper-postgres pg_dump -U postgres -d annotated-paper -Fc > "$DB_BACKUP"

echo "Cloning latest upstream..."
git clone --depth 1 "$UPSTREAM" "$TMP/openpaper"

MODE="patch"
if git -C "$TMP/openpaper" apply --check "$ROOT/openpaper.patch" 2>/dev/null; then
  git -C "$TMP/openpaper" apply "$ROOT/openpaper.patch"
  echo "Local changes applied as a patch."
else
  # A clean patch is preferable: it keeps upstream fixes in the files we touch.
  # If upstream changed those files, fall back to the full-file overlay so the
  # update still goes through; review upstream changes to those files later.
  cp -a "$ROOT/openpaper-overlay/." "$TMP/openpaper/"
  MODE="overlay"
  echo "Patch did not apply cleanly; local files restored from openpaper-overlay/."
fi

BACKUP=""
if [ -d "$CHECKOUT" ]; then
  BACKUP="$ROOT/openpaper.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CHECKOUT" "$BACKUP"
fi

mv "$TMP/openpaper" "$CHECKOUT"
ROLLBACK_READY=1
if [ -n "$BACKUP" ]; then
  for f in server/.env jobs/.env client/.env.local; do
    if [ -f "$BACKUP/$f" ]; then
      cp "$BACKUP/$f" "$CHECKOUT/$f"
    fi
  done
fi
chmod +x "$CHECKOUT"/scripts/*.sh 2>/dev/null || true

echo "Building images..."
docker compose build openpaper-server openpaper-jobs-api openpaper-client

echo "Applying migrations and restarting OpenPaper..."
docker compose up -d --force-recreate \
  openpaper-migrate \
  openpaper-server \
  openpaper-jobs-api \
  openpaper-jobs-worker \
  openpaper-jobs-beat \
  openpaper-client

echo
ROLLBACK_READY=0
echo "Updated using: $MODE"
echo "Database backup: $DB_BACKUP"
if [ -n "$BACKUP" ]; then
  echo "Previous checkout kept at: $BACKUP"
  echo "Rollback manually with: $ROOT/openpaper-rollback.sh"
fi
