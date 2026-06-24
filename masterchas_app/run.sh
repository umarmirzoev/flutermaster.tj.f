#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

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

FLUTTER="$(find_flutter)"
exec "$FLUTTER" run -d chrome "$@"
