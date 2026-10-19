---
title: "ansible-navigator et les execution environments"
description: "L'interface en mode texte d'Ansible, et l'image de conteneur qui rend une exécution reproductible"
objectives:
  - Expliquer ce qu'est un execution environment et pourquoi il rend un playbook reproductible
  - Installer ansible-navigator et lancer un playbook en mode stdout et en mode interactif
  - Lire le résultat d'une exécution dans l'interface en mode texte, et la rejouer depuis un artifact
  - Lancer un playbook dans un execution environment avec Docker (en option)
competencies:
  - ansible-navigator run, replay, --mode, --ee, --ce
  - Execution environments (images, ansible-builder)
  - Fichier de configuration ansible-navigator.yml
---

**ansible-navigator** est l'outil en ligne de commande qu'Ansible propose aux côtés
d'`ansible-playbook`. Il apporte deux choses : une **interface en mode texte** pour explorer une
exécution, et surtout l'exécution dans des **execution environments**, des images de conteneur qui
transportent Ansible et toutes ses dépendances. Ces images sont le maillon commun de tout ce cours :
AWX, Ascender et Ansible Automation Platform exécutent eux aussi les playbooks dedans.

Le chapitre commence par une présentation, puis vous fait installer navigator et lancer un premier
playbook. Le passage par une vraie image, plus lourd à télécharger, est proposé en option.
