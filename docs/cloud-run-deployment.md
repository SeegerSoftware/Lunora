# Deploiement Cloud Run

Ce projet est pret pour l'architecture suivante :

```text
Flutter app -> Firebase Auth/App Check -> Cloud Run FastAPI -> Firestore/OpenAI/Stripe
```

Cloud Run heberge uniquement le backend `backend/`. Les secrets restent cote serveur.

## Prerequis

- Google Cloud SDK installe : https://cloud.google.com/sdk/docs/install
- Projet Google/Firebase : `lunora-adb24`
- Facturation activee sur le projet Firebase/Google Cloud
- APIs activees :
  - Cloud Run
  - Cloud Build
  - Artifact Registry
  - Secret Manager
  - Firestore

## Connexion locale

```powershell
gcloud auth login
gcloud config set project lunora-adb24
```

## IAM Cloud Build

Depuis les changements Cloud Build recents, un nouveau projet peut utiliser le compte Compute Engine par defaut pour construire les images. Il doit avoir le role Cloud Run Builder.

```powershell
gcloud projects add-iam-policy-binding lunora-adb24 `
  --member="serviceAccount:94004835189-compute@developer.gserviceaccount.com" `
  --role="roles/run.builder"
```

Creer un compte dedie pour l'execution Cloud Run :

```powershell
gcloud iam service-accounts create elunai-api `
  --display-name="Elunai Cloud Run runtime"

gcloud projects add-iam-policy-binding lunora-adb24 `
  --member="serviceAccount:elunai-api@lunora-adb24.iam.gserviceaccount.com" `
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding lunora-adb24 `
  --member="serviceAccount:elunai-api@lunora-adb24.iam.gserviceaccount.com" `
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding lunora-adb24 `
  --member="serviceAccount:elunai-api@lunora-adb24.iam.gserviceaccount.com" `
  --role="roles/firebaseauth.admin"
```

## Secrets

Creer les secrets dans Secret Manager.

Version PowerShell :

```powershell
"sk-..." | gcloud secrets create OPENAI_API_KEY --data-file=-
"sk_live_..." | gcloud secrets create STRIPE_SECRET_KEY --data-file=-
"price_..." | gcloud secrets create STRIPE_PRICE_ID_ELUNAI --data-file=-
"whsec_..." | gcloud secrets create STRIPE_WEBHOOK_SECRET --data-file=-
```

Version Invite de commandes Windows (`cmd.exe`) :

```bat
echo sk-...| gcloud secrets create OPENAI_API_KEY --data-file=-
echo sk_live_...| gcloud secrets create STRIPE_SECRET_KEY --data-file=-
echo price_...| gcloud secrets create STRIPE_PRICE_ID_ELUNAI --data-file=-
echo whsec_...| gcloud secrets create STRIPE_WEBHOOK_SECRET --data-file=-
```

Remplacer les valeurs `sk-...`, `sk_live_...`, `price_...` et `whsec_...` par les vraies valeurs Stripe/OpenAI. Ne pas inclure les guillemets dans `cmd.exe`.

Si un secret existe deja, ajouter une nouvelle version au lieu de le recreer :

```powershell
"nouvelle-valeur" | gcloud secrets versions add OPENAI_API_KEY --data-file=-
```

Sur Cloud Run, ne pas definir `GOOGLE_APPLICATION_CREDENTIALS`. Le backend utilisera l'identite du service Cloud Run via Firebase Admin. Definir seulement `FIREBASE_PROJECT_ID`.

## Premier deploiement

Depuis la racine du repo :

```powershell
.\scripts\deploy-cloud-run.ps1
```

Equivalent manuel :

```powershell
gcloud run deploy elunai-api `
  --source backend `
  --region europe-west6 `
  --allow-unauthenticated `
  --port 8080 `
  --memory 512Mi `
  --cpu 1 `
  --min-instances 0 `
  --max-instances 10 `
  --service-account elunai-api@lunora-adb24.iam.gserviceaccount.com `
  --set-env-vars FIREBASE_PROJECT_ID=lunora-adb24,APP_CHECK_ENFORCED=false,GENERATION_RATE_LIMIT_PER_HOUR=12,OPENAI_MODEL=gpt-4o-mini,OPENAI_MAX_TOKENS=4500,OPENAI_TIMEOUT_SECONDS=45,OPENAI_MAX_ATTEMPTS=2,MAX_REQUEST_BODY_BYTES=131072,CORS_ALLOWED_ORIGINS=https://lunora.app;https://www.lunora.app,STRIPE_DEFAULT_PLAN_ID=plan_elunai,STRIPE_SUCCESS_URL=https://lunora.app/#/subscription/success,STRIPE_CANCEL_URL=https://lunora.app/#/subscription/cancel `
  --set-secrets OPENAI_API_KEY=OPENAI_API_KEY:latest,STRIPE_SECRET_KEY=STRIPE_SECRET_KEY:latest,STRIPE_PRICE_ID_ELUNAI=STRIPE_PRICE_ID_ELUNAI:latest,STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET:latest
```

Garder `APP_CHECK_ENFORCED=false` pour le premier test. Passer a `true` apres validation avec l'app mobile.

Deployer aussi les regles Firestore :

```powershell
.\scripts\deploy-firestore-rules.ps1
```

Avant ce passage, enregistrer l'application Android dans Firebase App Check avec
Play Integrity, installer un APK release sur un appareil physique et verifier
une generation complete. Une fois valide, relancer le script avec :

```powershell
.\scripts\deploy-cloud-run.ps1 -AppCheckEnforced true
```

## Verification

Apres deploiement, Cloud Run affiche une URL. Tester :

```powershell
curl https://<cloud-run-url>/health
curl https://<cloud-run-url>/mobile/config
```

La premiere reponse attendue est :

```json
{"ok":true}
```

## Stripe

Dans Stripe Dashboard, configurer le webhook vers :

```text
https://<cloud-run-url>/stripe/webhook
```

Evenements :

- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`

## Brancher l'app Flutter

Compiler l'app avec l'URL Cloud Run :

```powershell
flutter build apk `
  --dart-define=USE_FIREBASE=true `
  --dart-define=USE_SERVER_API=true `
  --dart-define=ELUNAI_API_BASE_URL=https://<cloud-run-url>
```

Pour iOS :

```powershell
flutter build ipa `
  --dart-define=USE_FIREBASE=true `
  --dart-define=USE_SERVER_API=true `
  --dart-define=ELUNAI_API_BASE_URL=https://<cloud-run-url>
```

## Signature Android de production

Sans `android/key.properties`, Gradle produit volontairement un APK release
installable localement mais signe avec la cle de debug. Cet APK n'est pas adapte
a une publication Play Store.

Creer une cle de signature hors du depot puis ajouter localement
`android/key.properties` :

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:\\chemin\\hors-du-depot\\elunai-upload-keystore.jks
```

Ne jamais committer le fichier `key.properties` ni le keystore.

## Passage production

Quand les appels mobiles fonctionnent :

```powershell
gcloud run services update elunai-api `
  --region europe-west6 `
  --update-env-vars APP_CHECK_ENFORCED=true
```

Puis relancer un test complet :

- connexion Firebase
- generation d'histoire
- checkout Stripe test
- webhook Stripe
- suppression de compte
