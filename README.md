# Elunai

La lecture audio des histoires utilise la synthese vocale locale de l'appareil.
La voix francaise peut etre choisie dans l'espace parent, sans envoyer le texte
vers un service audio externe.

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

## Cycle des histoires

- Les reglages du profil sont figes pendant une serie active. Une modification peut etre conservee pour la prochaine serie ou demarrer explicitement une nouvelle serie sans supprimer l'historique.
- Une série personnalisée contient 7 chapitres, avec un nouveau chapitre généré chaque jour.
- Les résumés et éléments de continuité sont conservés pour guider le chapitre suivant.
- Après le chapitre 7, la prochaine génération démarre une nouvelle série avec un identifiant distinct.
- La régénération admin du chapitre du jour remplace ce chapitre sans avancer artificiellement la série.

Le compte admin dispose aussi de deux actions de test : archiver une nouvelle histoire unique ou générer immédiatement une série complète de 7 chapitres. La série complète consomme environ 8 appels IA.

## Provisionner un administrateur

Le script backend crée le compte Firebase Auth s'il est absent, ajoute le claim `admin`,
active l'accès Elunai dans Firestore et conserve les claims existants :

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\chemin\firebase-service-account.json"
python backend\scripts\provision_admin.py --email gaetan.seeger@gmail.com --create-if-missing
```

Après provisionnement, se déconnecter puis se reconnecter pour rafraîchir le token Firebase.

## Mise en production

Voir le plan d'actions exportable : [`docs/release-action-plan.md`](docs/release-action-plan.md).

## Backend

```powershell
cd backend
docker compose up --build
```

- API : http://localhost:8000
- Santé : http://localhost:8000/health
- Config mobile : http://localhost:8000/mobile/config
