@echo off
setlocal
cd /d "%~dp0"

set BASE_URL=https://api.emaster.tj/api
set FLUTTER_CMD=flutter
where flutter >nul 2>&1
if not %ERRORLEVEL%==0 set FLUTTER_CMD=C:\Users\HP\flutter\bin\flutter.bat

echo ==============================================
echo 1/3: Building Flutter web (admin + superadmin)
echo ==============================================
call %FLUTTER_CMD% build web --no-web-resources-cdn --base-href "/" --dart-define=BASE_URL=%BASE_URL%
if errorlevel 1 goto BUILD_FAILED

echo.
echo ==============================================
echo 2/3: Copying build into MAsterrF\web\admin
echo ==============================================
robocopy "build\web" "..\..\MAsterrF\web\admin" /MIR /NFL /NDL /NJH /NJS
if %ERRORLEVEL% GEQ 8 goto COPY_FAILED

echo.
echo ==============================================
echo 3/3: Uploading admin web only (no cert/nginx changes)
echo ==============================================
cd /d "..\..\MAsterrF"
python scripts\deploy_admin_web_only.py
pause
exit /b 0

:BUILD_FAILED
echo BUILD FAILED.
pause
exit /b 1

:COPY_FAILED
echo COPY FAILED.
pause
exit /b 1
