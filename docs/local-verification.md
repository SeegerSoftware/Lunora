# Vérification locale

Ces commandes doivent être lancées dans un terminal où Flutter, Dart, Python et Git sont installés.

## 1. Backend mock

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:ALLOW_TEST_BEARER_TOKEN="true"
$env:OPENAI_MOCK="true"
$env:STRIPE_MOCK="true"
$env:ALLOW_TEST_APP_CHECK="true"
$env:APP_CHECK_ENFORCED="false"
$env:FIREBASE_PROJECT_ID="lunora-adb24"
$env:FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
$env:FIRESTORE_EMULATOR_HOST="localhost:8080"
pytest
uvicorn app.main:app --reload --port 8000
```

## 2. Firebase Emulator

Dans un autre terminal :

```powershell
firebase emulators:start --only auth,firestore
```

Si la CLI Firebase n'est pas installée :

```powershell
npm install -g firebase-tools
firebase login
```

## 3. App Flutter avec backend mock

Dans `dart_defines.json` :

```json
{
  "USE_FIREBASE": "true",
  "USE_SERVER_API": "true",
  "ELUNAI_API_BASE_URL": "http://localhost:8000",
  "USE_FIREBASE_EMULATOR": "true",
  "FIREBASE_EMULATOR_HOST": "localhost",
  "FIREBASE_AUTH_EMULATOR_PORT": "9099",
  "FIRESTORE_EMULATOR_PORT": "8080"
}
```

Puis :

```powershell
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter test integration_test --dart-define=RUN_BACKEND_INTEGRATION=true --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=USE_SERVER_API=true --dart-define=ELUNAI_API_BASE_URL=http://localhost:8000
```

## 4. Contrôle manuel

1. Créer un compte.
2. Compléter le profil enfant en 3 étapes.
3. Générer une histoire.
4. Ouvrir la lecture.
5. Ouvrir l'abonnement puis Stripe Checkout.
6. En backend mock, vérifier que `/stripe/webhook` est couvert par `pytest`.
