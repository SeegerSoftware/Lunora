# Elunai — backend (FastAPI)

Stack prévue : **FastAPI + PostgreSQL**. Pour l’instant, l’API expose seulement des endpoints minimaux ; la base PostgreSQL est déjà dans `docker-compose` pour le jour où tu brancheras SQLAlchemy.

## Prérequis

- Docker + Docker Compose

## Démarrer

À la racine de ce dossier `backend/` :

```bash
docker compose up --build
```

- API : <http://localhost:8000>
- Santé : <http://localhost:8000/health> → `{"ok":true}`
- Config mobile : <http://localhost:8000/mobile/config>

Docs interactives FastAPI : <http://localhost:8000/docs>

## Variables d’environnement

- `CORS_ALLOWED_ORIGINS` : liste séparée par virgules des origines autorisées.
  Exemple : `https://lunora.app,https://www.lunora.app`.
- `GOOGLE_APPLICATION_CREDENTIALS` : service account Firebase pour vérifier les ID tokens.
- `OPENAI_API_KEY` : clé OpenAI utilisée uniquement côté backend.
- `OPENAI_MODEL` : modèle de génération, par défaut `gpt-4o-mini`.
- `STRIPE_SECRET_KEY` : clé secrète Stripe côté serveur.
- `STRIPE_PRICE_ID_ELUNAI` : Price ID Stripe utilisé pour l'abonnement.
- `STRIPE_WEBHOOK_SECRET` : secret de signature du webhook Stripe.
- `STRIPE_SUCCESS_URL` / `STRIPE_CANCEL_URL` : URLs de retour Checkout.
- `APP_CHECK_ENFORCED=true` : exige un token Firebase App Check valide sur les endpoints protégés.
- `GENERATION_RATE_LIMIT_PER_HOUR` : limite de génération par utilisateur, par défaut `12`.

Voir `.env.example`. Copie vers `.env` si besoin.

## Endpoints applicatifs

- `POST /stories/generate` : protégé par `Authorization: Bearer <Firebase ID token>`.
  - `kind=story` génère une histoire.
  - `kind=series_bible` génère la bible de série.
- `POST /stripe/checkout` : protégé par Firebase ID token, retourne une URL Stripe Checkout.
- `POST /stripe/webhook` : webhook Stripe, vérifie la signature puis met à jour :
  - `subscriptions/{firebaseUid}`
  - `users/{firebaseUid}.subscriptionStatus`
- `DELETE /account` : protégé par Firebase ID token et App Check, supprime les données utilisateur et le compte Firebase Auth.

Le webhook attend `firebaseUid` et `planId` dans les métadonnées de la souscription Stripe. L'endpoint Checkout les place automatiquement dans la session.

## Configuration production

1. Crée un service account Firebase depuis Firebase Console → Project settings → Service accounts.
2. Déploie le JSON de service account uniquement côté serveur.
3. Défini `GOOGLE_APPLICATION_CREDENTIALS=/chemin/vers/service-account.json`.
4. Défini `FIREBASE_PROJECT_ID=lunora-adb24` ou l'id réel du projet.
5. Défini `OPENAI_API_KEY` uniquement dans l'environnement backend.
6. Défini `STRIPE_SECRET_KEY`, `STRIPE_PRICE_ID_ELUNAI` et `STRIPE_WEBHOOK_SECRET` côté backend.
7. Dans Stripe Dashboard, crée un webhook vers `https://ton-api/stripe/webhook` avec les événements :
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
8. Active App Check côté Firebase puis passe `APP_CHECK_ENFORCED=true` côté backend après validation sur staging.

## Tests backend

```bash
pytest
```

Les tests utilisent `ALLOW_TEST_BEARER_TOKEN=true`, `OPENAI_MOCK=true` et `STRIPE_MOCK=true`.

## Prochaines étapes (hors périmètre actuel)

- Vérification Firebase ID token sur les routes protégées
- Connexion PostgreSQL + modèles
- Appels OpenAI côté serveur uniquement
