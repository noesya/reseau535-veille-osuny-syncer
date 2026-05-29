# Réseau 535 - Veille artistique

Automate de synchronisation de la veille artistique du Réseau 535 vers le site osuny.

## Architecture

Les données sont présentes dans un document Grist et celles-ci sont synchronisés vers osuny via l'API.

## Workflow

- [x] On synchronise les objets satellites
  - [x] Les catégories d'organisations (Départements)
  - [x] Les catégories de projets (Disciplines, Thématiques)
  - [ ] Les organisations
    - [x] Equipes artistiques
    - [x] Opérateurs
    - [ ] Lieux
- On peut ensuite synchroniser les Spectacles
  - [ ] Infos principales : Nom, Synopsis, Année, Affiche (image)
  - [ ] Catégories : Discipline, Thématiques
  - [ ] Blocs de contenu
    - [ ] Bloc organisations : Créateur·trices
    - [ ] Bloc organisations : Etapes
      - En layout liste avec pour description l'état et les dates
    - [ ] Bloc tableaux : Informations
      - Une ligne pour l'âge minimum
      - Une ligne pour la durée (en minutes)
    - [ ] Bloc fichiers : Fichiers
      - Dossier
      - Fiche technique
    - [ ] Bloc organisations : Soutiens
