#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

WEB_HOST="${WEB_HOST:-127.0.0.1}"
WEB_PORT="${WEB_PORT:-58923}"

find_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi

  if [[ -n "${FLUTTER_ROOT:-}" && -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
    echo "${FLUTTER_ROOT}/bin/flutter"
    return 0
  fi

  local candidate
  for candidate in \
    "/c/Users/HP/flutter/bin/flutter" \
    "/c/src/flutter/bin/flutter" \
    "/c/flutter/bin/flutter" \
    "${HOME}/flutter/bin/flutter" \
    "${HOME}/development/flutter/bin/flutter"
  do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  cat >&2 <<'EOF'
Flutter не найден.

1. Установите Flutter: https://docs.flutter.dev/get-started/install
2. Добавьте папку bin Flutter в PATH, или задайте переменную:
   export FLUTTER_ROOT="/path/to/flutter"
3. Первый запуск после клонирования:
   flutter pub get
   ./run.sh
EOF
  return 1
}

cleanup_stuck_flutter() {
  taskkill //F //IM dart.exe >/dev/null 2>&1 || true
  rm -f "/c/Users/HP/flutter/bin/cache/lockfile" 2>/dev/null || true
}

FLUTTER="$(find_flutter)"
cleanup_stuck_flutter

# DEVICE=chrome -> авто-запуск Chrome (может падать с AppConnectionException).
# DEVICE=web-server (по умолчанию) -> стабильно, открываем URL в браузере вручную.
DEVICE="${DEVICE:-web-server}"

echo "Запуск: http://${WEB_HOST}:${WEB_PORT}" >&2
echo "Откройте этот адрес в Chrome (Ctrl+клик)." >&2

exec "$FLUTTER" run -d "$DEVICE" \
  --web-hostname="$WEB_HOST" \
  --web-port="$WEB_PORT" \
  "$@"
