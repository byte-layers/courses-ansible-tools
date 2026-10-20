---
title: "AWX, Tower, AAP et Ascender"
description: "La famille des plateformes Ansible, leur état aujourd'hui, Event-Driven Ansible, et deux cas pratiques au choix : AWX en Docker Compose, Ascender sur minikube"
objectives:
  - Situer AWX, Tower, Ansible Automation Platform et Ascender les uns par rapport aux autres
  - Connaître l'état actuel de chaque projet, et ce qu'il implique pour une équipe
  - Expliquer ce qu'apporte Event-Driven Ansible et où il s'intègre
  - Comprendre l'architecture d'AWX en la faisant tourner avec Docker Compose (montage non officiel)
  - Exploiter AWX en admin : cibles conteneurs, questionnaire, droits d'un opérateur, planning et audit
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

La première étape est une présentation, avec Event-Driven Ansible. Viennent ensuite **deux cas
pratiques, au choix** :

| Cas pratique | Voie | Ce qu'il faut |
|---|---|---|
| **AWX en Docker Compose**, puis **Aller plus loin avec AWX** | non officielle : on démonte AWX service par service, puis on l'exploite en admin sur des conteneurs cibles | Docker, 4 Go de mémoire, 5 minutes, puis 1 h 30 |
| **Ascender sur minikube** | officielle : l'opérateur Kubernetes, comme en entreprise | minikube, kubectl, helm, 8 Go de mémoire, 15 minutes |

Faites l'un, l'autre ou les deux. Pour celui que vous ne faites pas, lisez l'étape, marquez-la comme
terminée dans le sommaire du cours, et passez à la suite. Le quiz noté a sa propre étape, et ne
demande d'avoir réalisé aucun des deux.
