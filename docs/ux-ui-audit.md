# Audit UX/UI Lunora

## Direction produit

Objectif : une app parentale premium, douce, ludique et fiable. La direction retenue est `storybook premium` : fond crème, vert profond, accents miel, cartes nettes, microcopy rassurante, peu de décoration gratuite.

## Accueil

Constat initial : écran trop étiré sur desktop, hiérarchie faible, signaux de confiance absents.

Actions :
- refonte du hero avec proposition de valeur directe ;
- ajout de trois signaux de confiance : sécurisé, rituel calme, sur mesure ;
- largeur maximale centrée pour éviter l’effet maquette web ;
- CTA principal et secondaire clarifiés.

## Connexion

Constat initial : formulaire fonctionnel mais froid.

Actions :
- ajout d’un en-tête contextualisé ;
- largeur maximale centrée ;
- maintien du rappel email et du reset password.

## Inscription

Constat initial : trop proche d’un formulaire brut, microcopy peu structurée.

Actions :
- refonte du header ;
- clarification du parcours : compte d’abord, profil enfant ensuite ;
- maintien CGU explicite avant création de compte.

## Profil enfant

Constat : le flow par étapes est le bon modèle. Il reste à peaufiner visuellement les sections et à réduire les textes longs dans les cartes.

Recommandation suivante :
- harmoniser les cartes avec `LunoraPageHeader` et `LunoraActionTile` ;
- ajouter un récapitulatif final avant enregistrement ;
- rendre la progression plus compacte sur mobile.

## Accueil connecté

Constat : structure riche mais encore très chargée. L’écran combine dashboard, histoire du jour, historique et actions.

Recommandation suivante :
- transformer la carte histoire du jour en action centrale unique ;
- déplacer les actions secondaires vers des tuiles ;
- réduire les textes d’aide persistants après première utilisation.

## Bibliothèque

Constat initial : liste sombre, état vide peu premium.

Actions :
- refonte en bibliothèque claire ;
- état vide utile ;
- tuiles homogènes ;
- progression des séries visible.

## Lecture

Constat : le mode lecture est déjà différencié et utile. Le risque principal est la densité d’actions autour du texte.

Recommandation suivante :
- isoler les actions sociales derrière un bouton secondaire ;
- garder le texte comme héros de l’écran ;
- vérifier lisibilité sur petits écrans avec histoires longues.

## Parent

Constat : l’écran contient les bonnes fonctions, mais les raccourcis méritent une hiérarchie plus utilitaire.

Recommandation suivante :
- remplacer les boutons empilés par des tuiles avec titre + sous-titre ;
- isoler la suppression de compte dans une section danger ;
- ajouter une indication de confidentialité.

## Abonnement

Constat initial : statut et offre étaient lisibles mais pas assez rassurants pour un écran de paiement.

Actions :
- refonte du header ;
- carte statut explicite ;
- carte offre plus structurée ;
- message sécurité sur l’absence de clé Stripe côté app.

## Paiement succès / annulation

Constat initial : écran fonctionnel mais trop générique.

Actions :
- refonte avec carte centrale ;
- message précis sur webhook Stripe ;
- distinction claire succès / paiement interrompu.

## Priorités restantes

1. Refonte fine du profil enfant.
2. Refonte fine de l’accueil connecté.
3. Simplification du lecteur.
4. Audit visuel mobile réel après émulateur/device.
5. Tests bêta orientés parent : compréhension, confiance, temps jusqu’à première histoire.
