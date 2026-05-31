param(
    [string]$ProjectId = "lunora-adb24"
)

$ErrorActionPreference = "Stop"

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if (-not $gcloud) {
    throw "gcloud introuvable. Installe Google Cloud SDK puis relance ce script."
}

$token = (& $gcloud.Source auth print-access-token).Trim()
if (-not $token) {
    throw "Jeton gcloud introuvable. Lance gcloud auth login puis relance ce script."
}

$headers = @{
    Authorization = "Bearer $token"
    "x-goog-user-project" = $ProjectId
}
$rulesContent = [string](Get-Content (Join-Path $PSScriptRoot "..\firestore.rules") -Raw)
$rulesetBody = @{
    source = @{
        files = @(
            @{
                name = "firestore.rules"
                content = $rulesContent
            }
        )
    }
} | ConvertTo-Json -Depth 8

try {
    $ruleset = Invoke-RestMethod `
        -Method Post `
        -Uri "https://firebaserules.googleapis.com/v1/projects/$ProjectId/rulesets" `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $rulesetBody
} catch {
    $response = $_.Exception.Response
    if ($response) {
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        throw $reader.ReadToEnd()
    }
    throw
}

$releaseName = "projects/$ProjectId/releases/cloud.firestore"
$releaseBody = @{
    release = @{
        name = $releaseName
        rulesetName = $ruleset.name
    }
    updateMask = "rulesetName"
} | ConvertTo-Json -Depth 4

try {
    Invoke-RestMethod `
        -Method Patch `
        -Uri "https://firebaserules.googleapis.com/v1/$releaseName" `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $releaseBody | Out-Null
} catch {
    $response = $_.Exception.Response
    if ($response) {
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        throw $reader.ReadToEnd()
    }
    throw
}

Write-Host "Regles Firestore deployees : $($ruleset.name)"
