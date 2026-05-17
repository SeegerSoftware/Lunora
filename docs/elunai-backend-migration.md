# Elunai Backend-First Migration

Objectif: déplacer la logique métier côté serveur (OVH), garder Flutter pour l'affichage.

## Déjà lancé côté mobile (ce commit)

- Ajout de `MobileApiConfig`:
  - `USE_SERVER_API`
  - `ELUNAI_API_BASE_URL`
  - `ELUNAI_API_TIMEOUT_SECONDS`
- Ajout de `ElunaiApiClient` (GET/POST JSON + bearer token).
- Ajout de `elunaiApiClientProvider` dans la DI.

## Plan d'exécution recommandé

1. Backend API minimal
   - `GET /health`
   - `GET /mobile/config`
   - `GET /screen/home`
2. Auth serveur
   - Vérification token Firebase (`Authorization: Bearer ...`)
   - Mapping user backend
3. IA serveur
   - Endpoint `POST /stories/generate`
   - Appel OpenAI uniquement serveur
4. Data serveur
   - `GET /stories/today`
   - `GET /stories/history`
   - `PATCH /child-profile`
5. Bascule progressive mobile
   - Feature flag `USE_SERVER_API=true`
   - Remplacer les repositories Firebase un à un

## Ce que l'app enverra au backend

- Header: `Authorization: Bearer <firebase-id-token>`
- JSON: profil enfant, contexte série, préférences parent.

## Sécurité minimale avant prod

- Rate limiting par IP + user.
- Journaliser les erreurs OpenAI (sans données sensibles).
- Masquer toute clé API côté mobile.
- CORS strict si Web.
