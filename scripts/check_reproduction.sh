#!/bin/bash
# usage: scripts/check_reproduction.sh <python> <figure dir>
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
"${1:-python3}" scripts/check_reproduction.py "${2:-build/figures}"
