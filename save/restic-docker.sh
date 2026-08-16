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

DOCKER_MOUNTS=()

# Mount script directory (for excludes.txt, restic.env, etc.)
DOCKER_MOUNTS+=("-v" "$SCRIPT_DIR:$SCRIPT_DIR:ro")

# Mount backup source if defined and existing
if [ -n "$BACKUP_SOURCE" ] && [ -d "$BACKUP_SOURCE" ]; then
    DOCKER_MOUNTS+=("-v" "$BACKUP_SOURCE:$BACKUP_SOURCE:ro")
fi

# Mount local repo path if RESTIC_REPOSITORY is a local filesystem directory
if [[ "$RESTIC_REPOSITORY" == /* ]]; then
    mkdir -p "$RESTIC_REPOSITORY"
    DOCKER_MOUNTS+=("-v" "$RESTIC_REPOSITORY:$RESTIC_REPOSITORY")
fi

# Detect interactive TTY
TTY_FLAG=""
if [ -t 0 ]; then
    TTY_FLAG="-it"
fi

# Execute restic command inside disposable container
exec docker run --rm $TTY_FLAG \
    --env-file "$SCRIPT_DIR/restic.env" \
    "${DOCKER_MOUNTS[@]}" \
    restic/restic:latest "$@"
