#!/usr/bin/env bash
# Doyaken — one-time global setup
# Run: bash install.sh   (from the repo root)
#
# This script delegates to bin/install.sh which has the full implementation.
set -euo pipefail

DOYAKEN_DIR="${DOYAKEN_DIR:-$(cd "$(dirname "$0")" && pwd)}"
exec bash "$DOYAKEN_DIR/bin/install.sh" "$@"
