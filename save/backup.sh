#!/bin/bash
set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load restic configuration
if [ -f "$SCRIPT_DIR/restic.env" ]; then
    set -a
    source "$SCRIPT_DIR/restic.env"
    set +a
else
    echo "Error: restic.env not found in $SCRIPT_DIR"
    exit 1
fi

echo "=========================================="
echo "Starting Homelab Container Backup (via Docker)"
echo "Date: $(date)"
echo "Target Repository: $RESTIC_REPOSITORY"
echo "Source: $BACKUP_SOURCE"
echo "=========================================="

# Auto-initialize repository if local path and missing
if [[ "$RESTIC_REPOSITORY" == /* ]] && [ ! -d "$RESTIC_REPOSITORY/keys" ]; then
    echo "Initializing local repository at $RESTIC_REPOSITORY..."
    "$SCRIPT_DIR/restic-docker.sh" init
fi

# Perform container backup (ignoring container inode/ctime metadata changes)
echo "Creating snapshot..."
"$SCRIPT_DIR/restic-docker.sh" backup "$BACKUP_SOURCE" \
    --exclude-file="$SCRIPT_DIR/excludes.txt" \
    --ignore-inode \
    --ignore-ctime \
    --tag "monthly-containers" \
    --tag "homelab"

# Apply retention policy & prune (keep 12 monthly, 2 yearly snapshots)
echo "Applying retention policy (12 monthly, 2 yearly) & pruning..."
"$SCRIPT_DIR/restic-docker.sh" forget \
    --keep-monthly 12 \
    --keep-yearly 2 \
    --prune

echo "Backup and pruning completed successfully at $(date)!"
