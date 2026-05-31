# Elunai - Store Release Checklist

Date de mise a jour : 2026-05-31

## Bloquants avant soumission

- [ ] Remplacer Stripe Checkout dans les apps stores par une strategie conforme aux regles Apple App Store et Google Play pour les abonnements numeriques.
- [ ] Publier une politique de confidentialite accessible publiquement et la lier dans l'app et les fiches stores.
- [ ] Finaliser les CGU avec validation juridique.
- [ ] Ajouter un export de donnees utilisateur telechargeable ou un processus support documente.
- [ ] Afficher explicitement le consentement parent et la mention de contenu genere par IA.
- [ ] Valider la classification enfant/famille et les declarations Data Safety / App Privacy.
- [ ] Generer une signature Android release dediee. Ne pas publier un APK signe avec la cle debug.
- [ ] Produire et tester un AAB release pour Google Play Internal Testing.
- [ ] Produire et tester une archive iOS/TestFlight.

## Backend et securite

- [ ] Activer `APP_CHECK_ENFORCED=true` apres validation staging.
- [ ] Verifier que `OPENAI_API_KEY`, les secrets Stripe et les credentials Firebase restent uniquement cote backend.
- [ ] Deployer les regles `firestore.rules`.
- [ ] Deployer le backend FastAPI et verifier `GET /health`.
- [ ] Tester ownership, suppression de compte et quotas sur Firebase Emulator.
- [ ] Definir une politique de retention pour `story_generation_metrics` et `product_analytics_events`.
- [ ] Verifier les logs Cloud Run sans contenu narratif ni donnees enfant sensibles.
- [ ] Creer `STRIPE_PRICE_ID_SOLO` et `STRIPE_PRICE_ID_FAMILY` dans Secret Manager avant le prochain deploiement Cloud Run.
- [ ] Accorder au compte de release les droits App Distribution de lecture des releases pour confirmer les uploads REST.

## Paiements

- [ ] Tester paiement reussi, paiement echoue, renouvellement et annulation.
- [ ] Verifier la synchronisation `subscriptions/{uid}` et `users/{uid}`.
- [ ] Verifier les webhooks Stripe signes en staging.
- [ ] Documenter la restauration d'achat mobile avant lancement stores.

## Produit et IA

- [x] Profils narratifs par age 0-2, 3-4, 5-6, 7-8 et 9-12.
- [x] Score qualite 0-100 avec details et avertissements.
- [x] Memoire narrative avancee compatible avec les documents legacy.
- [x] Bibliotheque premium avec livres, progression, filtres, recherche et tri.
- [x] Architecture de couvertures differees et cachees.
- [x] Architecture audio backend-only preparee, non exposee dans l'offre.
- [x] Evenements analytics modelises.
- [x] Metriques IA et couts journalises cote backend.
- [ ] Brancher un worker asynchrone pour les couvertures.
- [ ] Brancher un worker asynchrone pour l'audio seulement apres validation produit.
- [ ] Construire le dashboard interne Firestore/BI pour les couts.

## Verification release

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `python -m pytest backend/tests -q`
- [ ] `flutter build apk --release --dart-define-from-file=dart_defines.json`
- [ ] `flutter build appbundle --release --dart-define-from-file=dart_defines.json`
- [ ] Test manuel Android sur appareil reel.
- [ ] Distribution Firebase App Distribution de l'APK beta.
