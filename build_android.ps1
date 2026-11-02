# KARE Help Desk - one-click Android build (Windows PowerShell)
# Run from the project folder (the one that contains pubspec.yaml):
#   powershell -ExecutionPolicy Bypass -File .\build_android.ps1

if (-not (Test-Path "lib\screens\login_screen.dart")) {
  Write-Host "ERROR: wrong folder. Open the folder that has lib, assets and pubspec.yaml inside." -ForegroundColor Red
  exit 1
}

if (-not (Test-Path "android\app\src\main\AndroidManifest.xml")) {
  Write-Host "Creating Android folders..."
  flutter create --org com.kare --project-name kare_helpdesk .
}

# 1) Internet permission
$manifest = "android\app\src\main\AndroidManifest.xml"
$text = Get-Content $manifest -Raw
if ($text -notmatch "android.permission.INTERNET") {
  $line = '<uses-permission android:name="android.permission.INTERNET"/>'
  $text = $text -replace "<application", ($line + "`r`n    <application")
  Set-Content -Path $manifest -Value $text
  Write-Host "Added INTERNET permission."
}

# 2) Firebase needs minSdk 23 or higher
foreach ($f in @("android\app\build.gradle.kts", "android\app\build.gradle")) {
  if (Test-Path $f) {
    $g = Get-Content $f -Raw
    $g2 = $g -replace "minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23" -replace "minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 23"
    if ($g2 -ne $g) { Set-Content -Path $f -Value $g2; Write-Host "Set minSdk to 23 in $f" }
  }
}

flutter pub get
flutter build apk --release

Write-Host ""
Write-Host "DONE. Your Android app file is:"
Write-Host "  build\app\outputs\flutter-apk\app-release.apk"
Write-Host "Upload it to Google Drive > Share > Anyone with the link."
