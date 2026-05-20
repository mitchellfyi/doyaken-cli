#!/usr/bin/env bash
# Dex — one-time global setup
# Run: bash install.sh   (from the repo root)
#
# This script delegates to bin/install.sh which has the full implementation.
set -euo pipefail

DEX_DIR="${DEX_DIR:-$(cd "$(dirname "$0")" && pwd)}"
exec bash "$DEX_DIR/bin/install.sh" "$@"
