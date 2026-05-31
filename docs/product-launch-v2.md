# Elunai - Fondations produit avant lancement

## Architecture ajoutee

- `StoryAgeProfile` cote backend pilote longueur, vocabulaire, structure, rythme, nombre de personnages et niveau emotionnel.
- Le score qualite retourne `qualityScore`, `qualityDetails` et `qualityWarnings`.
- Les histoires portent les contrats differes `coverImageUrl`, `coverImageStatus`, `coverPrompt`, `audioStatus`, `audioUrl`, `audioVoice` et `audioDuration`.
- La memoire de serie accepte relations, mysteres, objets narratifs, emotions, evenements majeurs et `doNotRepeat`.
- La bibliotheque regroupe les chapitres en livres et expose recherche, filtre et tri.
- `AnalyticsService` centralise les evenements produit sans contenu enfant.
- `StoryGenerationMetrics` journalise tokens, cout estime, duree, score qualite, reecritures et fallback.

## Collections Firestore

Nouvelles collections :

- `product_analytics_events/{eventId}` : evenement produit minimal, cree par le client authentifie.
- `story_generation_metrics/{metricId}` : detail prive par generation, ecrit uniquement par le backend.
- `story_generation_daily/{yyyy-MM-dd}` : agregats journaliers prives, ecrits uniquement par le backend.

Champs ajoutes sans migration obligatoire :

- `stories/*` : qualite, couverture differee et audio differe.
- `child_series_state/*` : relations, mysteres, objets narratifs, emotions, evenements et anti-repetition.

Les documents existants restent compatibles grace aux valeurs par defaut des modeles Flutter.

## Risques restant ouverts

- Les abonnements numeriques stores necessitent une strategie conforme Apple/Google avant soumission.
- Les agregats de cout sont prepares mais le dashboard de visualisation reste a construire.
- Les listes de memoire sont bornees cote Flutter pour limiter la croissance des documents. Le chemin quotidien backend devra aussi etre surveille a grande echelle.
- Les couvertures et l'audio sont prepares mais volontairement non generes pour eviter un cout non maitrise avant mesure d'usage.
- Le deploiement Cloud Run attend deux secrets distincts `STRIPE_PRICE_ID_SOLO` et `STRIPE_PRICE_ID_FAMILY`. L'ancien secret unique `STRIPE_PRICE_ID_ELUNAI` ne doit pas etre reutilise pour les deux offres.
