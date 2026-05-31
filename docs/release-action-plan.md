# Plan d'actions release Elunai

Objectif : rendre Elunai publiable App Store / Google Play avec un niveau professionnel.

## Actions à faire par le propriétaire du projet

Ces actions nécessitent tes comptes, tes secrets, ou des décisions business/légales.

### 1. Comptes et accès

- Créer ou vérifier le compte Apple Developer.
- Créer ou vérifier le compte Google Play Console.
- Vérifier l'accès propriétaire Firebase au projet `lunora-adb24`.
- Vérifier l'accès administrateur Stripe.
- Vérifier l'accès OpenAI Platform.
- Choisir l'environnement de déploiement backend : Cloud Run, Render, Railway, Fly.io ou autre.

### 2. Secrets production

- Générer une nouvelle clé OpenAI.
- Révoquer toute ancienne clé OpenAI exposée ou utilisée côté client.
- Créer une clé Stripe production.
- Créer le Price ID Stripe production pour l'abonnement Elunai.
- Créer un service account Firebase Admin.
- Stocker le fichier service account uniquement côté serveur.
- Ne jamais mettre ces secrets dans `dart_defines.json`, GitHub, Cursor, Flutter ou l'app mobile.

Variables backend production à définir :

```env
GOOGLE_APPLICATION_CREDENTIALS=/secure/path/firebase-service-account.json
FIREBASE_PROJECT_ID=lunora-adb24
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-4o-mini
STRIPE_SECRET_KEY=...
STRIPE_PRICE_ID_SOLO=...
STRIPE_PRICE_ID_FAMILY=...
STRIPE_WEBHOOK_SECRET=...
STRIPE_SUCCESS_URL=https://ton-domaine/success
STRIPE_CANCEL_URL=https://ton-domaine/cancel
CORS_ALLOWED_ORIGINS=https://ton-domaine
```

### 3. Stripe

- Créer le produit Stripe `Elunai`.
- Créer le prix mensuel correspondant.
- Copier les deux `price_id` dans `STRIPE_PRICE_ID_SOLO` et `STRIPE_PRICE_ID_FAMILY`.
- Déclarer le webhook Stripe vers :

```text
https://ton-backend/stripe/webhook
```

- Activer les événements Stripe :
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
- Copier le webhook signing secret dans `STRIPE_WEBHOOK_SECRET`.
- Faire un paiement test complet avant production.

### 4. Firebase

- Activer Firebase Authentication email/password.
- Configurer Google Sign-In correctement.
- Configurer Apple Sign-In si publication iOS.
- Vérifier les règles Firestore en mode production.
- Activer Firebase App Check.
- Enregistrer les apps Android/iOS dans App Check.
- Activer `APP_CHECK_ENFORCED=true` côté backend après test staging.
- Préparer les domaines autorisés Firebase Auth.
- Préparer le flux suppression de compte et données.

### 5. Légal et conformité enfants

- Rédiger une politique de confidentialité.
- Rédiger les conditions d'utilisation.
- Ajouter une page contact/support.
- Ajouter une procédure de suppression de compte.
- Ajouter une procédure de suppression des données enfant.
- Valider les obligations liées aux enfants : RGPD, COPPA si marché US, règles Apple/Google.
- Décider si l'app cible officiellement les enfants ou les parents.
- Éviter tout tracking non nécessaire.
- Ne pas ajouter de publicité comportementale.

### 6. Store listing

- Utiliser le nom final `Elunai` sur tous les supports publics.
- Harmoniser le branding partout.
- Préparer icône app.
- Préparer screenshots Android.
- Préparer screenshots iPhone.
- Préparer description courte.
- Préparer description longue.
- Préparer mots-clés App Store.
- Préparer URL privacy policy.
- Préparer URL support.
- Définir catégorie et âge cible.
- Remplir les formulaires data safety Google Play.
- Remplir les privacy nutrition labels Apple.

### 7. Validation locale à lancer

Dans un terminal avec Flutter, Python, Firebase CLI et Git installés :

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest
```

Puis à la racine du projet :

```powershell
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
```

Avec backend mock + Firebase Emulator :

```powershell
firebase emulators:start --only auth,firestore
```

Dans un autre terminal :

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
$env:ALLOW_TEST_BEARER_TOKEN="true"
$env:OPENAI_MOCK="true"
$env:STRIPE_MOCK="true"
$env:FIREBASE_PROJECT_ID="lunora-adb24"
$env:FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
$env:FIRESTORE_EMULATOR_HOST="localhost:8080"
uvicorn app.main:app --reload --port 8000
```

Puis :

```powershell
flutter test integration_test --dart-define=RUN_BACKEND_INTEGRATION=true --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=USE_SERVER_API=true --dart-define=ELUNAI_API_BASE_URL=http://localhost:8000
```

### 8. Décisions produit

- Décider si l'histoire est générée automatiquement chaque jour ou uniquement après action explicite.
- Décider si l'abonnement est obligatoire avant génération.
- Décider du quota d'histoires par jour.
- Décider si les parents peuvent modifier/supprimer une histoire.
- Décider si plusieurs enfants par compte sont supportés dès la V1.
- Décider de la langue V1 : français seulement ou FR/EN.

## Actions que Codex peut faire dans le projet

Ces actions peuvent être faites dans le code sans accès à tes comptes.

### Release engineering

- Ajouter une checklist release technique.
- Ajouter une configuration d'environnements `dev/staging/prod`.
- Ajouter une page d'état backend mobile.
- Ajouter un écran erreur maintenance / backend indisponible.
- Ajouter un logger backend structuré.
- Ajouter des tests backend supplémentaires.
- Ajouter des tests Flutter supplémentaires.
- Nettoyer les textes mojibake visibles dans PowerShell si confirmés dans l'app.

### Sécurité app

- Ajouter App Check côté Flutter.
- Ajouter vérification App Check côté backend.
- Ajouter endpoint suppression compte.
- Ajouter suppression Firestore liée à l'utilisateur.
- Ajouter limitation simple de génération par utilisateur.
- Ajouter validation stricte des payloads backend avec Pydantic.
- Ajouter rate limiting backend.

### UX/UI

- Améliorer l'onboarding parent.
- Simplifier le profil enfant.
- Améliorer l'écran abonnement.
- Améliorer les états de chargement génération IA.
- Ajouter écran succès paiement.
- Ajouter écran paiement annulé.
- Ajouter gestion claire des erreurs génération.
- Améliorer bibliothèque et reprise des séries.

### Qualité

- Ajouter tests des règles Firestore.
- Ajouter test intégration backend mock complet.
- Ajouter test widget du flow profil en 3 étapes.
- Ajouter test parsing webhook Stripe.
- Ajouter test suppression de compte.

## Ordre recommandé

1. Finaliser secrets et backend production.
2. Finaliser Stripe webhook en test.
3. Activer Firebase Emulator et valider le test intégration.
4. Ajouter suppression compte/données.
5. Ajouter App Check.
6. Nettoyer UX onboarding/profil/abonnement.
7. Lancer `flutter analyze`, `flutter test`, `pytest`.
8. Préparer TestFlight et Google Play Internal Testing.
9. Corriger les retours bêta.
10. Soumettre aux stores.
