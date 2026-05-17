# Lance l'app avec les defines du fichier dart_defines.json (racine du projet).
# 1) Copie dart_defines.example.json -> dart_defines.json
# 2) Configure USE_SERVER_API / ELUNAI_API_BASE_URL si tu utilises le backend local
# 3) Si lib/firebase_options.dart est absent : flutterfire configure (ou dart run flutterfire_cli:flutterfire configure)
# 4) .\run.ps1   (ou : flutter run --dart-define-from-file=dart_defines.json)

# Flutter : PATH utilisateur (nouveau terminal) ou emplacement par défaut de ce setup
$flutterBin = "C:\src\flutter\bin"
if (Test-Path $flutterBin) {
    $env:Path = "$flutterBin;" + $env:Path
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter introuvable. Installe-le (C:\src\flutter) ou redémarre le terminal après avoir ajouté flutter\bin au PATH."
    exit 1
}

$defines = Join-Path $PSScriptRoot "dart_defines.json"
if (-not (Test-Path $defines)) {
    Write-Error "Fichier manquant : dart_defines.json`nCopie dart_defines.example.json vers dart_defines.json et renseigne les variables locales nécessaires."
    exit 1
}

flutter run --dart-define-from-file=dart_defines.json @args
