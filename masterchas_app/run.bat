@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  flutter run -d chrome %*
  exit /b %ERRORLEVEL%
)

if defined FLUTTER_ROOT (
  if exist "%FLUTTER_ROOT%\bin\flutter.bat" (
    "%FLUTTER_ROOT%\bin\flutter.bat" run -d chrome %*
    exit /b %ERRORLEVEL%
  )
)

if exist "C:\Users\HP\flutter\bin\flutter.bat" (
  "C:\Users\HP\flutter\bin\flutter.bat" run -d chrome %*
  exit /b %ERRORLEVEL%
)

echo Flutter ne nayden.
echo Ustanovite Flutter SDK i dobavte ego v PATH.
echo Ili zadayte FLUTTER_ROOT na papku s Flutter.
echo Posle klonirovaniya: flutter pub get
exit /b 1
