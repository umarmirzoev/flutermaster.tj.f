@echo off
setlocal
cd /d "%~dp0"

if not defined WEB_HOST set WEB_HOST=localhost
if not defined WEB_PORT set WEB_PORT=58923
if not defined BASE_URL set BASE_URL=http://91.227.41.158/api

echo Podgotovka: ostanavlivayu staryye processy Flutter...

taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM dartaotruntime.exe >nul 2>&1
timeout /t 1 /nobreak >nul

if exist build\flutter_assets rmdir /s /q build\flutter_assets >nul 2>&1
if exist build\web rmdir /s /q build\web >nul 2>&1
if exist .dart_tool\hooks_runner rmdir /s /q .dart_tool\hooks_runner >nul 2>&1
if exist "C:\Users\HP\flutter\bin\cache\lockfile" del /f "C:\Users\HP\flutter\bin\cache\lockfile" >nul 2>&1
if exist "C:\Users\HP\flutter\bin\cache\flutter.bat.lock" del /f "C:\Users\HP\flutter\bin\cache\flutter.bat.lock" >nul 2>&1

echo Zapusk: http://%WEB_HOST%:%WEB_PORT%
echo Dozhdites stroki: lib\main.dart is being served at http://%WEB_HOST%:%WEB_PORT%

where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  flutter run -d web-server --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --no-web-resources-cdn --dart-define=BASE_URL=%BASE_URL% %*
  exit /b %ERRORLEVEL%
)

if defined FLUTTER_ROOT (
  if exist "%FLUTTER_ROOT%\bin\flutter.bat" (
    "%FLUTTER_ROOT%\bin\flutter.bat" run -d web-server --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --no-web-resources-cdn --dart-define=BASE_URL=%BASE_URL% %*
    exit /b %ERRORLEVEL%
  )
)

if exist "C:\Users\HP\flutter\bin\flutter.bat" (
  "C:\Users\HP\flutter\bin\flutter.bat" run -d web-server --web-hostname=%WEB_HOST% --web-port=%WEB_PORT% --no-web-resources-cdn --dart-define=BASE_URL=%BASE_URL% %*
  exit /b %ERRORLEVEL%
)

echo Flutter ne nayden.
echo Ustanovite Flutter SDK i dobavte ego v PATH.
echo Ili zadayte FLUTTER_ROOT na papku s Flutter.
echo Posle klonirovaniya: flutter pub get
exit /b 1
