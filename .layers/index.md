---
title: "Ansible — outils de gestion et d'exécution"
description: "Du terminal à la plateforme : ansible-navigator et les execution environments, ansible-pull, Semaphore UI, puis AWX, AAP et Ascender"
tags:
  - ansible
  - devops
  - lab
difficulty: intermediate
duration: 240
introTitle: "Présentation"
requires: "0.1.0"
options:
  allowManualProgress: false
  autoCompleteOnNext: unverifiable
---

Écrire un playbook est une chose ; le faire tourner **en équipe**, **régulièrement**, avec des
**secrets**, des **droits** et une **trace** de ce qui a été exécuté en est une autre. Ce cours
parcourt les outils qui répondent à ces besoins, du plus léger au plus complet, et vous fait
pratiquer ceux qui se lancent sur un simple poste.

## Pour qui ?

Ce cours vise un niveau **intermédiaire**. Il suppose que vous savez :

- lire et lancer un playbook (`ansible-playbook`), écrire un inventaire ;
- utiliser Docker et Docker Compose (`docker run`, `docker compose up`) ;
- faire un commit avec git.

Si un de ces points vous manque, le cours « Ansible — premiers pas » couvre les bases d'Ansible.

## Ce qu'il faut sur votre poste

| Outil | Version | Pourquoi |
|---|---|---|
| bash | macOS, Linux, ou **WSL 2** sous Windows | Ansible ne s'exécute pas nativement sous Windows |
| Docker | Docker Engine ou Docker Desktop, avec **Compose v2** | les machines et Semaphore tournent en conteneurs |
| Python | **3.12** ou plus récent | ansible-navigator s'installe dans un environnement Python |
| git | n'importe quelle version récente | les outils du cours tirent leur configuration d'un dépôt git |
| `curl` | n'importe quelle version | tester les API |

## Le parcours

1. **Du terminal à la plateforme** : ce qui manque à `ansible-playbook` quand on passe à
   l'équipe, et la grille de critères qui structure tout le cours.
2. **ansible-navigator et les execution environments** : l'interface en mode texte, et l'image
   de conteneur qui transporte Ansible et ses dépendances.
3. **ansible-pull** : le mode pull natif d'Ansible, sans aucune plateforme, et la réconciliation
   d'une dérive.
4. **Semaphore UI** : un contrôleur web léger, lancé en un `compose.yml`, avec projets,
   templates et plannings.

Deux chapitres suivront dans une prochaine version : le paysage **AWX, Tower, AAP et Ascender**
(avec Event-Driven Ansible), et **choisir son outil**.

Les chapitres sont indépendants les uns des autres : chacun prépare ses propres fichiers dans
`atelier/` et nettoie ses conteneurs à la fin. Les fichiers fournis et les solutions de référence
sont dans le dossier `lab/` du dépôt.
