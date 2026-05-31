# Elunai — configuration environnement de dev (Windows)
# Usage : powershell -ExecutionPolicy Bypass -File .\setup-dev.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [Environment]::GetEnvironmentVariable("Path", "User")
}

function Ensure-FlutterPath {
    $flutterBin = "C:\src\flutter\bin"
    if (-not (Test-Path "$flutterBin\flutter.bat")) {
        Write-Host "Flutter absent. Clone stable dans C:\src\flutter ..."
        New-Item -ItemType Directory -Force -Path C:\src | Out-Null
        git clone https://github.com/flutter/flutter.git -b stable --depth 1 C:\src\flutter
    }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
        Write-Host "PATH utilisateur : ajout de $flutterBin"
    }
    Refresh-Path
}

Write-Host "=== Elunai — setup dev ===" -ForegroundColor Cyan

Ensure-FlutterPath
flutter --version
flutter config --enable-windows-desktop | Out-Null

Set-Location $ProjectRoot
flutter pub get

if (-not (Test-Path "$ProjectRoot\dart_defines.json")) {
    Copy-Item "$ProjectRoot\dart_defines.example.json" "$ProjectRoot\dart_defines.json"
    Write-Warning "dart_defines.json créé depuis l'exemple. Renseigne ELUNAI_API_BASE_URL et les clés Stripe/Google nécessaires."
}

if (-not (Test-Path "$ProjectRoot\lib\firebase_options.dart")) {
    Write-Warning "lib/firebase_options.dart manquant. Lance : dart pub global activate flutterfire_cli ; flutterfire configure"
}

Write-Host ""
Write-Host "=== flutter doctor ===" -ForegroundColor Cyan
flutter doctor

Write-Host ""
Write-Host "=== Prochaines étapes manuelles ===" -ForegroundColor Yellow
Write-Host "1. Android Studio : premier lancement → installer SDK + créer un émulateur"
Write-Host "2. Docker Desktop : premier lancement → activer WSL2 si demandé"
Write-Host "3. Visual Studio 2022 : charge de travail « Développement Desktop en C++ » (app Windows)"
Write-Host "4. flutterfire configure (si Firebase pas encore généré)"
Write-Host "5. Lancer l'app : .\run.ps1   ou   flutter run -d chrome --dart-define-from-file=dart_defines.json"
