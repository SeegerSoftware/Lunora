# Lance l'app avec les defines du fichier dart_defines.json (racine du projet).
# 1) Copie dart_defines.example.json -> dart_defines.json
# 2) Remplace OPENAI_API_KEY par ta vraie clé
# 3) Si lib/firebase_options.dart est absent : flutterfire configure (ou dart run flutterfire_cli:flutterfire configure)
# 4) .\run.ps1   (ou : flutter run --dart-define-from-file=dart_defines.json)

$defines = Join-Path $PSScriptRoot "dart_defines.json"
if (-not (Test-Path $defines)) {
    Write-Error "Fichier manquant : dart_defines.json`nCopie dart_defines.example.json vers dart_defines.json et renseigne OPENAI_API_KEY."
    exit 1
}

flutter run --dart-define-from-file=dart_defines.json @args
