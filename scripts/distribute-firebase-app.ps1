param(
    [string]$ProjectNumber = "94004835189",
    [string]$AppId = "1:94004835189:android:136aa5bfeb3801addf593c",
    [string]$ApkPath = "build\app\outputs\flutter-apk\app-release.apk"
)

$ErrorActionPreference = "Stop"

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if (-not $gcloud) {
    throw "gcloud introuvable. Installe Google Cloud SDK puis relance ce script."
}

$resolvedApk = (Resolve-Path $ApkPath).Path
$token = (& $gcloud.Source auth print-access-token).Trim()
if (-not $token) {
    throw "Jeton gcloud introuvable. Lance gcloud auth login puis relance ce script."
}

$headers = @{
    Authorization = "Bearer $token"
    "X-Goog-Upload-Protocol" = "raw"
    "X-Goog-Upload-File-Name" = [System.IO.Path]::GetFileName($resolvedApk)
}
$appResource = "projects/$ProjectNumber/apps/$AppId"
$uploadUrl = "https://firebaseappdistribution.googleapis.com/upload/v1/$appResource/releases:upload"
$operation = Invoke-RestMethod `
    -Method Post `
    -Uri $uploadUrl `
    -Headers $headers `
    -ContentType "application/vnd.android.package-archive" `
    -InFile $resolvedApk
Write-Host "Upload Firebase App Distribution soumis : $($operation.name)"

try {
    for ($attempt = 0; $attempt -lt 30 -and -not $operation.done; $attempt++) {
        Start-Sleep -Seconds 2
        $operation = Invoke-RestMethod `
            -Method Get `
            -Uri "https://firebaseappdistribution.googleapis.com/v1/$($operation.name)" `
            -Headers @{ Authorization = "Bearer $token" }
    }
} catch {
    Write-Host "Lecture de l'operation interdite. Verification de la release la plus recente..."
    Start-Sleep -Seconds 3
    try {
        $latest = Invoke-RestMethod `
            -Method Get `
            -Uri "https://firebaseappdistribution.googleapis.com/v1/$appResource/releases?pageSize=1" `
            -Headers @{ Authorization = "Bearer $token" }
        $release = $latest.releases[0]
    } catch {
        Write-Host "Upload soumis. Confirmation impossible avec les droits IAM actuels."
        return
    }
}

if (-not $release -and -not $operation.done) {
    throw "Upload Firebase App Distribution toujours en cours apres 60 secondes."
}
if (-not $release -and $operation.error) {
    throw "Upload Firebase App Distribution refuse : $($operation.error.message)"
}

if (-not $release) {
    $release = $operation.response.release
}
Write-Host "APK distribue sur Firebase App Distribution."
Write-Host "Release : $($release.name)"
Write-Host "Console : $($release.firebaseConsoleUri)"
Write-Host "Test : $($release.testingUri)"
