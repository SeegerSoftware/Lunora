param(
    [string]$ProjectId = "lunora-adb24",
    [string]$Region = "europe-west6",
    [string]$ServiceName = "elunai-api",
    [string]$RuntimeServiceAccount = "elunai-api@lunora-adb24.iam.gserviceaccount.com",
    [string]$AppCheckEnforced = "false"
)

$ErrorActionPreference = "Stop"

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if (-not $gcloud) {
    throw "gcloud introuvable. Installe Google Cloud SDK puis relance ce script."
}

& $gcloud.Source config set project $ProjectId

& $gcloud.Source run deploy $ServiceName `
    --source backend `
    --region $Region `
    --allow-unauthenticated `
    --port 8080 `
    --memory 512Mi `
    --cpu 1 `
    --min-instances 0 `
    --max-instances 10 `
    --service-account $RuntimeServiceAccount `
    --set-env-vars "FIREBASE_PROJECT_ID=$ProjectId,APP_CHECK_ENFORCED=$AppCheckEnforced,GENERATION_RATE_LIMIT_PER_HOUR=12,OPENAI_MODEL=gpt-4o-mini,OPENAI_MAX_TOKENS=4500,OPENAI_TIMEOUT_SECONDS=45,OPENAI_MAX_ATTEMPTS=2,OPENAI_VALIDATION_ATTEMPTS=2,MAX_REQUEST_BODY_BYTES=131072,CORS_ALLOWED_ORIGINS=https://lunora.app;https://www.lunora.app,STRIPE_DEFAULT_PLAN_ID=plan_elunai,STRIPE_SUCCESS_URL=https://lunora.app/#/subscription/success,STRIPE_CANCEL_URL=https://lunora.app/#/subscription/cancel" `
    --set-secrets "OPENAI_API_KEY=OPENAI_API_KEY:latest,STRIPE_SECRET_KEY=STRIPE_SECRET_KEY:latest,STRIPE_PRICE_ID_ELUNAI=STRIPE_PRICE_ID_ELUNAI:latest,STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET:latest"
