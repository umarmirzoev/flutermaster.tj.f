#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

WEB_HOST="${WEB_HOST:-localhost}"
WEB_PORT="${WEB_PORT:-58923}"
BASE_URL="${BASE_URL:-http://91.227.41.158/api}"

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
    "/c/Users/HP/flutter/bin/flutter.bat" \
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

# Останавливает зависшие процессы и снимает блокировку build/ (Windows).
cleanup_stuck_flutter() {
  echo "Подготовка: останавливаю старые процессы Flutter..." >&2

  taskkill //F //IM dart.exe >/dev/null 2>&1 || true
  taskkill //F //IM dartaotruntime.exe >/dev/null 2>&1 || true

  rm -f "/c/Users/HP/flutter/bin/cache/lockfile" 2>/dev/null || true
  rm -f "/c/Users/HP/flutter/bin/cache/flutter.bat.lock" 2>/dev/null || true

  local app_dir
  app_dir="$(pwd -W 2>/dev/null || pwd)"

  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "
      Get-Process dart,dartaotruntime -ErrorAction SilentlyContinue | Stop-Process -Force
      Start-Sleep -Milliseconds 900
      Set-Location -LiteralPath '$app_dir'
      foreach (\$dir in @('build\\flutter_assets', 'build\\web', '.dart_tool\\hooks_runner')) {
        if (Test-Path \$dir) { Remove-Item -Recurse -Force \$dir -ErrorAction SilentlyContinue }
      }
      Remove-Item -Force 'C:\\Users\\HP\\flutter\\bin\\cache\\lockfile' -ErrorAction SilentlyContinue
      Remove-Item -Force 'C:\\Users\\HP\\flutter\\bin\\cache\\flutter.bat.lock' -ErrorAction SilentlyContinue
    " >/dev/null 2>&1 || true
  else
    rm -rf build/flutter_assets build/web .dart_tool/hooks_runner 2>/dev/null || true
  fi

  sleep 1
}

FLUTTER="$(find_flutter)"
cleanup_stuck_flutter

# DEVICE=chrome -> авто-запуск Chrome (может падать с AppConnectionException).
# DEVICE=web-server (по умолчанию) -> стабильно, открываем URL в браузере вручную.
DEVICE="${DEVICE:-web-server}"

echo "Запуск: http://${WEB_HOST}:${WEB_PORT}" >&2
echo "Дождитесь строки: lib\\main.dart is being served at http://${WEB_HOST}:${WEB_PORT}" >&2
echo "Затем откройте этот адрес в Chrome." >&2

exec "$FLUTTER" run -d "$DEVICE" \
  --web-hostname="$WEB_HOST" \
  --web-port="$WEB_PORT" \
  --no-web-resources-cdn \
  --dart-define=BASE_URL="$BASE_URL" \
  "$@"
