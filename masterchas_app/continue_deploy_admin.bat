@echo off
setlocal
cd /d "%~dp0"

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

:COPY_FAILED
echo COPY FAILED.
pause
exit /b 1
