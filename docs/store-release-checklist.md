# Checklist mise en ligne

## Backend production

- Creer l'environnement backend de production.
- Definir uniquement cote backend :
  - `GOOGLE_APPLICATION_CREDENTIALS`
  - `FIREBASE_PROJECT_ID`
  - `OPENAI_API_KEY`
  - `STRIPE_SECRET_KEY`
  - `STRIPE_PRICE_ID_ELUNAI`
  - `STRIPE_WEBHOOK_SECRET`
  - `APP_CHECK_ENFORCED=true` apres validation staging
  - `GENERATION_RATE_LIMIT_PER_HOUR`
- Verifier que le client mobile ne contient aucune cle secrete.
- Exposer les endpoints HTTPS :
  - `GET /health`
  - `POST /stories/generate`
  - `POST /stripe/checkout`
  - `POST /stripe/webhook`
  - `DELETE /account`

## Stripe test

- Creer ou verifier le produit/prix Stripe test.
- Configurer le webhook test vers `https://<backend>/stripe/webhook`.
- Activer les evenements :
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
- Verifier dans Firestore que `subscriptions/{uid}` et `users/{uid}` changent apres paiement test.

## Firebase

- Installer Firebase CLI si besoin : `npm install -g firebase-tools`.
- Se connecter : `firebase login`.
- Lancer les emulateurs : `firebase emulators:start --only auth,firestore`.
- Lancer le backend mock avec :
  - `ALLOW_TEST_BEARER_TOKEN=true`
  - `ALLOW_TEST_APP_CHECK=true`
  - `OPENAI_MOCK=true`
  - `STRIPE_MOCK=true`
  - `FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`
  - `FIRESTORE_EMULATOR_HOST=localhost:8080`
- Lancer le test integration avec `RUN_BACKEND_INTEGRATION=true`.

## App stores

- iOS/TestFlight :
  - Verifier bundle id, icones, splash, permissions, privacy manifest si requis.
  - Creer App Store Connect app.
  - Configurer abonnement in-app ou redirection conforme a la strategie retenue.
  - Uploader build archive depuis Xcode.
  - Inviter testeurs internes TestFlight.
- Android/Internal testing :
  - Verifier application id, icones, versionCode/versionName.
  - Generer keystore release et configurer signature.
  - Creer app Google Play Console.
  - Remplir Data safety, contenu enfants/famille si applicable, politique de confidentialite.
  - Uploader AAB en Internal testing.

## Beta

- Collecter retours : crash, paiement, creation profil, generation, lecture, suppression compte.
- Classer chaque retour : bloquant, majeur, mineur.
- Corriger les bloquants avant toute soumission store.
- Relancer :
  - `flutter analyze`
  - `flutter test`
  - `pytest backend/tests`
  - test integration emulateurs
