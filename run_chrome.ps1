# KARE Help Desk - one-click run in Chrome
#   powershell -ExecutionPolicy Bypass -File .\run_chrome.ps1

if (-not (Test-Path "lib\screens\login_screen.dart")) {
  Write-Host "ERROR: wrong folder. Open the folder that has lib, assets and pubspec.yaml inside." -ForegroundColor Red
  exit 1
}

if (-not (Test-Path "web")) {
  Write-Host "Creating platform folders..."
  flutter create --org com.kare --project-name kare_helpdesk .
}

flutter pub get
flutter run -d chrome
