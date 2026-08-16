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
    echo "❌ Error: restic.env not found in $SCRIPT_DIR"
    exit 1
fi

echo "=========================================="
echo "🚀 Starting Homelab Container Backup"
echo "Date: $(date)"
echo "Target Repository: $RESTIC_REPOSITORY"
echo "Source: $BACKUP_SOURCE"
echo "=========================================="

# Ensure restic binary exists
if ! command -v restic &> /dev/null; then
    echo "❌ Error: restic is not installed. Please run 'sudo apt install restic'."
    exit 1
fi

# Auto-initialize repository if local path and missing
if [[ "$RESTIC_REPOSITORY" == /* ]] && [ ! -d "$RESTIC_REPOSITORY/keys" ]; then
    echo "📦 Initializing local repository at $RESTIC_REPOSITORY..."
    mkdir -p "$RESTIC_REPOSITORY"
    restic init
fi

# Perform container backup
echo "📸 Creating snapshot..."
restic backup "$BACKUP_SOURCE" \
    --exclude-file="$SCRIPT_DIR/excludes.txt" \
    --tag "weekly-containers" \
    --tag "homelab"

# Apply retention policy & prune (keep 4 weekly, 12 monthly snapshots)
echo "🧹 Applying retention policy (4 weekly, 12 monthly) & pruning..."
restic forget \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --keep-yearly 1 \
    --prune

echo "✅ Backup and pruning completed successfully at $(date)!"
