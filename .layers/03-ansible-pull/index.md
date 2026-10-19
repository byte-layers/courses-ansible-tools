---
title: "ansible-pull : le pull natif"
description: "Une machine qui tire elle-même sa configuration d'un dépôt git, sans aucune plateforme"
objectives:
  - Expliquer le fonctionnement d'ansible-pull et ses options principales
  - Faire converger une machine depuis un dépôt git, à chaque cycle
  - Constater la correction automatique d'une dérive
  - Comprendre pourquoi l'option -o ne corrige pas une dérive
competencies:
  - ansible-pull (-U, -d, -C, -o)
  - Planification par cron ou timer systemd
  - Réconciliation et déclenchement sur commit
---

**ansible-pull** est livré avec Ansible lui-même, à côté d'`ansible-playbook`. Il inverse le sens
habituel : au lieu qu'un poste pousse la configuration vers les machines, chaque machine **clone un
dépôt git** et **s'applique** le playbook qu'il contient. Lancé régulièrement, il fait de chaque
machine un agent de réconciliation, sans serveur ni plateforme.

Ce chapitre en pose le principe, puis vous fait monter une « machine » en conteneur qui se configure
toute seule depuis un dépôt git local, et observer ce qui se passe quand le dépôt change, et quand
la machine dérive.
