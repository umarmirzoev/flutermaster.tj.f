@echo off
setlocal
cd /d "%~dp0"

if not defined WEB_HOST set WEB_HOST=127.0.0.1
if not defined WEB_PORT set WEB_PORT=58923

taskkill /F /IM dart.exe >nul 2>&1
if exist "C:\Users\HP\flutter\bin\cache\lockfile" del /f "C:\Users\HP\flutter\bin\cache\lockfile" >nul 2>&1

echo Запуск: http://%WEB_HOST%:%WEB_PORT%

where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  flutter run -d chrome --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --web-browser-flag=--disable-extensions %*
  exit /b %ERRORLEVEL%
)

if defined FLUTTER_ROOT (
  if exist "%FLUTTER_ROOT%\bin\flutter.bat" (
    "%FLUTTER_ROOT%\bin\flutter.bat" run -d chrome --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --web-browser-flag=--disable-extensions %*
    exit /b %ERRORLEVEL%
  )
)

if exist "C:\Users\HP\flutter\bin\flutter.bat" (
  "C:\Users\HP\flutter\bin\flutter.bat" run -d chrome --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --web-browser-flag=--disable-extensions %*
  exit /b %ERRORLEVEL%
)

echo Flutter ne nayden.
echo Ustanovite Flutter SDK i dobavte ego v PATH.
echo Ili zadayte FLUTTER_ROOT na papku s Flutter.
echo Posle klonirovaniya: flutter pub get
exit /b 1
