@echo off
rem KARE Help Desk - change phone icon + app name, then build the APK
rem Put this file in the project folder (where pubspec.yaml is) and double-click it.
cd /d "%~dp0"

if not exist pubspec.yaml (
  echo ERROR: put this file inside the kare_helpdesk_firebase folder, next to pubspec.yaml
  pause
  exit /b 1
)
if not exist assets\images\kare_logo.png (
  echo ERROR: assets\images\kare_logo.png not found
  pause
  exit /b 1
)

echo [1/4] Adding icon tool...
call flutter pub add --dev flutter_launcher_icons

echo [2/4] Writing icon settings...
(
echo flutter_launcher_icons:
echo   android: true
echo   ios: false
echo   image_path: "assets/images/kare_logo.png"
echo   min_sdk_android: 23
) > flutter_launcher_icons.yaml

echo [3/4] Making icons and app name...
call dart run flutter_launcher_icons
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; (Get-Content $f -Raw) -replace 'android:label=\"[^\"]*\"','android:label=\"KARE Help Desk\"' | Set-Content $f"

echo [4/4] Building the APK (takes a few minutes)...
call flutter build apk --release

echo.
echo ================================================
echo DONE. Your new app file is here:
echo %~dp0build\app\outputs\flutter-apk\app-release.apk
echo Upload it to Google Drive. On the phone, UNINSTALL the old app first, then install.
echo ================================================
pause
