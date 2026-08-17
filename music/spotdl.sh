#!/usr/bin/env bash
# spotDL helper wrapper script for Homelab
docker exec -it spotdl-web uv run --project /app --no-sync spotdl "$@"
