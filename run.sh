#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/masterchas_app/run.sh" "$@"
