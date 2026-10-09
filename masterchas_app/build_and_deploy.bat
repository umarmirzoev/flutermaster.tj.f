@echo off
setlocal
cd /d "%~dp0"

set BASE_URL=https://api.emaster.tj/api

echo ==============================================
echo 1/3: Building Flutter web (admin + superadmin)
echo ==============================================
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  flutter build web --no-web-resources-cdn --base-href "/" --dart-define=BASE_URL=%BASE_URL%
) else (
  "C:\Users\HP\flutter\bin\flutter.bat" build web --no-web-resources-cdn --base-href "/" --dart-define=BASE_URL=%BASE_URL%
)
if errorlevel 1 (
  echo BUILD FAILED.
  pause
  exit /b 1
)

echo.
echo ==============================================
echo 2/3: Copying build into MAsterrF\web\admin
echo ==============================================
robocopy "build\web" "..\..\MAsterrF\web\admin" /MIR /NFL /NDL /NJH /NJS
if %ERRORLEVEL% GEQ 8 (
  echo COPY FAILED.
  pause
  exit /b 1
)

echo.
echo ==============================================
echo 3/3: Deploying to server
echo ==============================================
cd /d "..\..\MAsterrF"
call scripts\deploy_now.bat
