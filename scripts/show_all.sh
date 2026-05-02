#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$0")"

"$DIR/show_raw.sh"
echo
"$DIR/show_marts.sh"
