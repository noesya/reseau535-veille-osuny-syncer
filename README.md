# Réseau 535 - Veille artistique

Automate de synchronisation de la veille artistique du Réseau 535 vers le site osuny.

## Setup & Run

### Setup

- Cloner le repo
- Dupliquer le fichier `.env.example` pour créer votre `.env`
- Installer les dépendances avec `bundle install`

### Run

Lancer la synchronisation avec `bin/sync`

## Architecture

Les données sont présentes dans un document Grist et celles-ci sont synchronisés vers osuny via l'API.

On synchronise les éléments ayant été mis à jour dans les 2 derniers jours. (Période configurable via la constante `Grist::Models::Base::SYNCABLE_DAYS_THRESHOLD`).

- [x] On synchronise les objets satellites
  - [x] Les catégories d'organisations (Départements)
  - [x] Les catégories de projets (Disciplines, Thématiques)
  - [x] Les organisations
- On peut ensuite synchroniser les Spectacles
  - [x] Infos principales : Titre, Sous-titre, Synopsis, Année, Affiche (image)
  - [x] Catégories : Discipline, Thématiques
  - [x] Blocs de contenu
    - [x] Bloc organisations : Créateur·trices (Equipes artistiques)
    - [x] Bloc tableaux : Informations
      - Une ligne pour l'étape
      - Une ligne pour l'âge minimum
      - Une ligne pour la durée (en minutes)
    - [x] Bloc CTA : Lien vers un dossier Drive des fichiers du spectacle
    - [x] Bloc organisations : Soutiens (Opérateurs)
    - [x] Bloc vidéo : Teaser vidéo sur YouTube
    - [x] Bloc chapitre : Commentaire public
    - Etapes
      - [x] Bloc titre
      - [x] Bloc tableau : Liste des étapes dans l'ordre chronologique
      - [x] Bloc organisations : Liste des lieux impliqués dans l'ordre alphabétique
      - [x] Bloc organisations : Liste des opérateurs impliqués dans l'ordre alphabétique
