---
title: "AWX, Tower, AAP et Ascender"
description: "La famille des plateformes Ansible, leur état aujourd'hui, Event-Driven Ansible, et un cas pratique Ascender sur minikube"
objectives:
  - Situer AWX, Tower, Ansible Automation Platform et Ascender les uns par rapport aux autres
  - Connaître l'état actuel de chaque projet, et ce qu'il implique pour une équipe
  - Expliquer ce qu'apporte Event-Driven Ansible et où il s'intègre
  - Déployer Ascender sur un cluster minikube avec son opérateur, et y lancer un job
competencies:
  - Lignée Tower, AWX, automation controller, Ascender
  - Objets d'un contrôleur AWX (organisation, projet, inventaire, template, job)
  - Opérateur Kubernetes et ressource personnalisée AWX
  - Rulebooks Event-Driven Ansible
---

Semaphore a montré le modèle d'un contrôleur en version légère. Ce chapitre présente la famille
qui a inventé ce modèle : **Ansible Tower**, devenu l'**automation controller** de **Red Hat Ansible
Automation Platform** (AAP), son projet amont libre **AWX**, et **Ascender**, une version dérivée
d'AWX maintenue par l'éditeur CIQ. Beaucoup d'entreprises utilisent encore AWX, ou même Tower : il
faut savoir s'y retrouver.

La première étape est une présentation, avec Event-Driven Ansible. La seconde, un cas pratique
**plus lourd que les autres** : déployer Ascender sur un cluster Kubernetes local, minikube, avec son
opérateur. Ses prérequis sont détaillés en tête d'étape ; si votre poste ne les remplit pas, lisez
l'étape sans la faire, marquez-la comme terminée dans le sommaire du cours, et passez au quiz, qui a
sa propre étape.
