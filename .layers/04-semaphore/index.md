---
title: "Semaphore UI"
description: "Un contrôleur web léger : projet, dépôt, inventaire, template, planning, et la même chose par l'API"
objectives:
  - Lancer Semaphore UI et sa base avec Docker Compose
  - Créer dans l'interface un dépôt, un inventaire et un template, puis lancer une tâche
  - Planifier une exécution et constater la correction d'une dérive
  - Distinguer un planning cron et un déclenchement sur commit
  - Piloter Semaphore par son API
competencies:
  - Modèle projet, dépôt, inventaire, template, planning
  - Healthcheck et depends_on dans Compose
  - API REST d'un contrôleur Ansible
---

**Semaphore UI** est un contrôleur web open source pour Ansible (et aussi pour Terraform, OpenTofu
ou de simples scripts bash). Il reprend le modèle d'AWX, *projet, template, planning*, avec un
poids bien moindre : un binaire Go et une base de données, qui se lancent en un `compose.yml`. C'est
l'outil idéal pour **voir** le fonctionnement d'un contrôleur sans héberger de cluster Kubernetes.

Le chapitre avance en trois étapes : lancer Semaphore, créer et lancer un premier template dans
l'interface, puis le planifier et le piloter par l'API. Le chapitre est validé sur Semaphore
**v2.19.16** ; l'interface est en anglais, les noms de menus sont donc cités tels quels.
