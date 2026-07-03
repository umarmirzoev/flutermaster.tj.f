#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BASE_URL="${BASE_URL:-http://91.227.41.158/api}"

echo "Building Flutter web (local CanvasKit, no CDN)..."
flutter build web --no-web-resources-cdn --dart-define=BASE_URL="$BASE_URL"

echo
echo "Admin panel: http://localhost:8082/admin/login"
echo "Use localhost, NOT 127.0.0.1 (CORS)."
echo
python tools/serve_web.py --host localhost --port 8082
