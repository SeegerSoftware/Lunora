param(
    [string]$ProjectId = "lunora-adb24",
    [string]$Region = "europe-west6",
    [string]$ServiceName = "elunai-api",
    [string]$JobName = "elunai-daily-stories",
    [string]$SchedulerServiceAccount = "elunai-scheduler@lunora-adb24.iam.gserviceaccount.com"
)

$ErrorActionPreference = "Stop"
$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if (-not $gcloud) {
    throw "gcloud introuvable. Installe Google Cloud SDK puis relance ce script."
}

& $gcloud.Source config set project $ProjectId
& $gcloud.Source services enable cloudscheduler.googleapis.com

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $gcloud.Source iam service-accounts describe $SchedulerServiceAccount --project $ProjectId 2>$null
$serviceAccountExists = $LASTEXITCODE -eq 0
$ErrorActionPreference = $previousErrorActionPreference
if (-not $serviceAccountExists) {
    & $gcloud.Source iam service-accounts create elunai-scheduler `
        --project $ProjectId `
        --display-name "Elunai daily story scheduler"
}

$serviceUrl = & $gcloud.Source run services describe $ServiceName `
    --project $ProjectId `
    --region $Region `
    --format "value(status.url)"

& $gcloud.Source run services update $ServiceName `
    --project $ProjectId `
    --region $Region `
    --update-env-vars "SCHEDULER_AUDIENCE=$serviceUrl,SCHEDULER_SERVICE_ACCOUNT_EMAIL=$SchedulerServiceAccount,DAILY_STORY_MAX_PROFILES=500"

$ErrorActionPreference = "Continue"
& $gcloud.Source scheduler jobs describe $JobName --location $Region --project $ProjectId 2>$null
$jobExists = $LASTEXITCODE -eq 0
$ErrorActionPreference = $previousErrorActionPreference
if ($jobExists) {
    $action = "update"
} else {
    $action = "create"
}

& $gcloud.Source scheduler jobs $action http $JobName `
    --project $ProjectId `
    --location $Region `
    --schedule "0 12 * * *" `
    --time-zone "Europe/Zurich" `
    --uri "$serviceUrl/internal/daily-stories/publish" `
    --http-method POST `
    --oidc-service-account-email $SchedulerServiceAccount `
    --oidc-token-audience $serviceUrl
