# Lance Elunai dans Chrome (debug)
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$flutterBin = "C:\src\flutter\bin"
if (Test-Path $flutterBin) {
    $env:Path = "$flutterBin;" + $env:Path
}

Set-Location $ProjectRoot
Write-Host "Elunai - lancement (Chrome)..." -ForegroundColor Cyan
& (Join-Path $ProjectRoot "run.ps1") -d chrome

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Appuyez sur Entree pour fermer..." -ForegroundColor Yellow
    Read-Host | Out-Null
}
