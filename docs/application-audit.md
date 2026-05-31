# Audit application Elunai

Date : 2026-05-17

## Fonctionnalités présentes

- Authentification email/password, Google, Apple côté repository.
- Profil enfant avec prénom, âge, langue, thèmes, personnage, style, univers, ton et notes libres.
- Génération d'histoire quotidienne, série en chapitres, historique, lecture classique et mode coucher.
- Mémoire narrative Firestore : univers long terme et snapshots récents.
- Abonnement avec état Firestore, écran d'offre et écran Stripe préparatoire.
- Backend FastAPI minimal : santé, configuration mobile, PostgreSQL préparé dans Docker Compose.

## Points forts

- Découpage Flutter propre par features.
- Riverpod et repositories clairement séparés.
- Règles Firestore centrées sur l'ownership utilisateur.
- Modèles métier déjà riches : enfant, histoire, série, abonnement, mémoire.
- UX cohérente autour du rituel du soir : accueil, histoire du jour, bibliothèque, lecture.

## Risques prioritaires

1. Clé OpenAI côté client.
   La génération directe depuis Flutter expose la clé dans une app publiée. Migration backend nécessaire avant production.

2. Paiement Stripe incomplet.
   L'écran actuel est un placeholder avec activation test. La création de Checkout Session ou PaymentIntent doit être côté backend.

3. Génération automatique depuis l'accueil.
   `todayStoryProvider` appelle `ensureTodayStory`, donc ouvrir l'accueil peut déclencher un appel IA coûteux. Pour la production, préférer une action explicite ou une file serveur contrôlée.

4. Peu ou pas de tests visibles.
   Les dossiers `test/` et `integration_test/` ne contiennent pas de tests détectés. Les règles de génération, mappers Firestore et parcours auth/profil devraient être couverts.

5. Backend encore non utilisé pour les flux sensibles.
   Le client backend existe, mais les repositories critiques restent directement Firebase/OpenAI côté mobile.

## UX/UI

- Accueil : clair, mais le CTA "Créer une histoire" et l'auto-génération peuvent se chevaucher conceptuellement.
- Profil enfant : complet, mais dense. Une progression en étapes serait plus lisible pour un parent non technique.
- Lecture : bonne base avec taille de police, badges, feedback et partage. Le partage d'extrait doit rester strictement limité.
- Historique : utile, mais les séries et histoires unitaires pourraient être mieux distinguées visuellement.
- Abonnement : à clarifier tant que le paiement réel n'est pas branché. Éviter toute ambiguïté entre test et production.

## Modifications appliquées

- Suppression de la clé OpenAI locale dans `dart_defines.json`.
- Remplacement du placeholder `sk-...` dans `dart_defines.example.json`.
- Ajout d'une navigation sûre `safePopOrGo()` pour éviter les crashs sur routes ouvertes directement.
- Application de ce fallback aux écrans auth, lecture, historique, parent, abonnement et paiement.
- Durcissement CORS du backend via `CORS_ALLOWED_ORIGINS`.
- README remplacé par une documentation fidèle à l'état réel du projet.
- Ajout de `/stories/generate` côté FastAPI, protégé par Firebase ID token.
- Déplacement du client OpenAI hors mobile : le client Flutter appelle désormais le backend via `BackendStoryGenerationService`.
- Ajout de `/stripe/checkout` côté FastAPI, protégé par Firebase ID token.
- Ajout de `/stripe/webhook` côté FastAPI pour mettre à jour Firestore après événement Stripe.
- Transformation du profil enfant en parcours par étapes.
- Ajout de tests unitaires validators, mappers, parsing/normalisation de génération, et tests backend API.

## Prochaines étapes recommandées

1. Brancher Firebase Admin en production via `GOOGLE_APPLICATION_CREDENTIALS`.
2. Configurer `OPENAI_API_KEY` et `STRIPE_SECRET_KEY` uniquement côté backend.
3. Remplacer l'activation test d'abonnement par un webhook Stripe qui met Firestore à jour.
4. Activer le test d'intégration complet avec Firebase Emulator et backend mock.
5. Exécuter `flutter analyze`, `flutter test` et `pytest` dans un environnement avec les outils installés.
