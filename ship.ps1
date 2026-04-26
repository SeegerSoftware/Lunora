# Commit + push rapide avec garde-fou local.
# Usage:
#   .\ship.ps1 -Message "fix: corriger la navigation"
#   .\ship.ps1 -Message "feat: ..." -SkipAnalyze

param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Message)) {
    Write-Error "Le message de commit est obligatoire."
    exit 1
}

$repoRoot = $PSScriptRoot
Set-Location $repoRoot

$status = git status --porcelain
if (-not $status) {
    Write-Host "Aucun changement à commit."
    exit 0
}

if (-not $SkipAnalyze) {
    Write-Host "Analyse Flutter en cours..."
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Error "flutter analyze a échoué. Corrige d'abord les erreurs."
        exit 1
    }
}

Write-Host "Ajout des fichiers..."
git add -A

Write-Host "Commit..."
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Error "Le commit a échoué."
    exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Error "Impossible de déterminer la branche courante."
    exit 1
}

Write-Host "Push vers origin/$branch..."
git push origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Le push a échoué."
    exit 1
}

Write-Host "Terminé: commit + push réussis sur $branch."
