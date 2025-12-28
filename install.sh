#!/usr/bin/env bash
# Doyaken — one-time global setup
# Run: bash ~/work/doyaken/install.sh
#
# This script delegates to bin/install.sh which has the full implementation.
set -euo pipefail

DOYAKEN_DIR="${DOYAKEN_DIR:-$HOME/work/doyaken}"
exec bash "$DOYAKEN_DIR/bin/install.sh" "$@"
