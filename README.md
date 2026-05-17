# Lunora

Application Flutter pour générer des histoires du soir personnalisées pour les enfants.

## État du projet

- App Flutter structurée par fonctionnalités : auth, profil enfant, histoires, mémoire narrative, abonnement.
- Firebase Auth et Cloud Firestore sont utilisés côté mobile.
- Génération IA côté backend via FastAPI.
- Backend FastAPI présent dans `backend/` pour les appels sensibles : OpenAI, Stripe Checkout.

## Lancer l'app

1. Copier `dart_defines.example.json` vers `dart_defines.json`.
2. Renseigner uniquement les valeurs locales nécessaires.
3. Pour la génération IA et Stripe côté serveur, définir :
   - `USE_SERVER_API=true`
   - `ELUNAI_API_BASE_URL=http://localhost:8000`
4. Lancer :

```powershell
.\run.ps1
```

## Sécurité

Ne jamais versionner `dart_defines.json`, `.env`, les fichiers Firebase natifs ou une clé OpenAI réelle.

La génération OpenAI doit passer par le backend. Ne place pas de clé OpenAI dans les `dart-defines` de l'app mobile.

## Backend

```powershell
cd backend
docker compose up --build
```

- API : http://localhost:8000
- Santé : http://localhost:8000/health
- Config mobile : http://localhost:8000/mobile/config
