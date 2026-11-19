#!/usr/bin/env bash
# Recreate the patched OpenPaper checkout used by docker-compose.yml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHECKOUT="$ROOT/openpaper"
UPSTREAM="https://github.com/khoj-ai/openpaper.git"
PIN="cad4a819461b626763098375b2919d72e5e59f92"

cd "$ROOT"

if [ ! -d "$CHECKOUT/.git" ]; then
  git clone "$UPSTREAM" "$CHECKOUT"
  git -C "$CHECKOUT" fetch origin "$PIN" --depth 1 || true
  git -C "$CHECKOUT" checkout --detach "$PIN"
fi

if git -C "$CHECKOUT" apply --check "$ROOT/openpaper.patch" 2>/dev/null; then
  git -C "$CHECKOUT" apply "$ROOT/openpaper.patch"
  echo "Applied openpaper.patch"
else
  echo "Patch already applied (or does not apply cleanly); leaving checkout as-is"
fi

if ! grep -q '^OPENCODE_GO_API_KEY=' "$ROOT/.env" 2>/dev/null; then
  echo "WARNING: OPENCODE_GO_API_KEY is missing from $ROOT/.env" >&2
fi

echo "OpenPaper checkout ready at $CHECKOUT"
