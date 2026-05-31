# Commit + push vers origin/main (demande un message si des fichiers ont change)
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

function Get-GitAuthor {
    $last = git log -1 --format="%an|%ae" 2>$null
    if ($last -match "^(.+)\|(.+)$") {
        return @{ Name = $Matches[1]; Email = $Matches[2] }
    }
    return $null
}

Write-Host "=== Elunai - Push GitHub ===" -ForegroundColor Cyan
git status

$porcelain = git status --porcelain
if (-not $porcelain) {
    Write-Host ""
    Write-Host "Aucun changement local. Push des commits existants..." -ForegroundColor Yellow
    git push origin main
    if ($LASTEXITCODE -eq 0) { Write-Host "OK - a jour sur GitHub." -ForegroundColor Green }
}
else {
    Write-Host ""
    Write-Host "Fichiers modifies detectes." -ForegroundColor Yellow
    $msg = Read-Host "Message de commit (Entree vide = annuler)"
    if ([string]::IsNullOrWhiteSpace($msg)) {
        Write-Host "Annule." -ForegroundColor Red
    }
    else {
        $author = Get-GitAuthor
        if (-not $author) {
            Write-Host "Configure Git : git config --global user.name / user.email" -ForegroundColor Red
        }
        else {
            git add -A
            $stagedSecrets = git diff --cached --name-only | Where-Object {
                $_ -match "dart_defines\.json$|firebase_options\.dart$|google-services\.json$|\.env$"
            }
            if ($stagedSecrets) {
                Write-Host "Refus : fichiers secrets detectes dans le commit :" -ForegroundColor Red
                $stagedSecrets | ForEach-Object { Write-Host "  - $_" }
                git reset HEAD
            }
            else {
                git -c "user.name=$($author.Name)" -c "user.email=$($author.Email)" commit -m $msg
                if ($LASTEXITCODE -eq 0) {
                    git push origin main
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Host "Pousse sur https://github.com/SeegerSoftware/Elunai" -ForegroundColor Green
                    }
                }
            }
        }
    }
}

Write-Host ""
Write-Host "Appuyez sur Entree pour fermer..."
Read-Host | Out-Null
