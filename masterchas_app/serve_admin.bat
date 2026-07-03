@echo off
setlocal
cd /d "%~dp0"

set BASE_URL=http://91.227.41.158/api

echo Building Flutter web (local CanvasKit, no CDN)...
call flutter build web --no-web-resources-cdn --dart-define=BASE_URL=%BASE_URL%
if errorlevel 1 exit /b 1

echo.
echo Starting admin panel at http://localhost:8082/admin/login
echo Use localhost, NOT 127.0.0.1 (CORS).
echo.
python tools\serve_web.py --host localhost --port 8082
