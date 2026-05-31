# Identifiants infrastructure legacy

La marque publique et le nom interne de l'application sont `Elunai`.

Les identifiants ci-dessous conservent temporairement leur valeur historique.
Ils pointent vers des ressources externes déjà provisionnées et ne doivent pas
être renommés sans migration coordonnée :

- projet Firebase / Google Cloud : `lunora-adb24`
- package Android Firebase et Play : `lunora.v00`
- bundle Apple : `com.lunora.lunora`
- comptes de service rattachés au projet Firebase
- URLs historiques `lunora.app` tant que les DNS, Stripe et redirections ne
  sont pas migrés vers un domaine Elunai validé

Une migration future devra créer ou reconfigurer les ressources Firebase,
OAuth, App Check, stores, DNS et Stripe avant de modifier ces valeurs dans le
code.
