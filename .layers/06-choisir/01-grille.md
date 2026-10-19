---
title: "La grille, et des cas concrets"
description: "Tous les outils du cours sur une même grille, puis six situations à trancher"
---

## La grille remplie

Voici la grille du premier chapitre, remplie avec ce que vous avez vu. Une case vide ne veut pas
dire « impossible », mais « à construire soi-même » :

| Besoin | ansible-playbook | ansible-navigator | ansible-pull | Pipeline CI | Semaphore UI | AWX, Ascender, AAP |
|---|---|---|---|---|---|---|
| **Reproductibilité** | dépend du poste | **EE** | dépend de chaque machine | image du job | Ansible embarqué | **EE** par job |
| **Déclenchement** | manuel | manuel | **cron**, sur commit (`-o`) | commit, planning, manuel | **planning**, sur commit, webhook | **planning**, webhook, **événement** : EDA (AAP), React (Ascender), à part pour AWX |
| **Secrets** | à la main, Ansible Vault | idem | sur chaque machine | variables masquées | **stockés** (Key Store) | **stockés**, coffres externes |
| **Droits** | aucun | aucun | aucun | ceux du dépôt | équipes, rôles simples | **fins** : organisations, équipes, rôles par objet |
| **Traçabilité** | la console | **artifacts** | un journal par machine | journal des jobs | historique central | historique central, **audit** (Activity Stream) |
| **Interface** | terminal | terminal (TUI) | aucune | celle de la CI | **web** et API | **web**, API, collection Ansible |
| **À héberger** | rien | rien (Docker ou Podman pour les EE) | rien | la CI existante | un conteneur et une base | **un cluster Kubernetes**, ou l'installeur de l'éditeur |

La colonne **Pipeline CI** n'a pas eu de chapitre, mais c'est souvent la première marche réelle en
entreprise : un job GitLab CI ou GitHub Actions qui lance `ansible-playbook` (ou navigator, dans une
image d'EE) à chaque fusion, avec la passphrase du vault dans une variable masquée.

## La règle de décision

Une seule règle suffit pour la plupart des cas : **prenez la marche la plus basse qui couvre vos
besoins réels**, pas vos besoins imaginés. Chaque marche au-dessus ajoute du code à maintenir, un
service à surveiller, des mises à jour à suivre.

Trois questions départagent presque toujours :

1. **Faut-il corriger les dérives sans intervention ?** Si oui, il faut un planning : ansible-pull,
   une CI planifiée, ou un contrôleur.
2. **Plusieurs équipes, avec des droits différents, doivent-elles lancer des playbooks ?** Si oui,
   un contrôleur avec des droits fins devient utile : Ascender, AWX, ou AAP.
3. **Faut-il un support éditeur, ou un audit opposable ?** Si oui, AAP avec une souscription
   Red Hat, ou Ascender avec l'offre de CIQ.

## Quiz final

Chaque question décrit une situation réelle. Choisissez l'outil le plus adapté, au sens de la règle
ci-dessus. Ce quiz valide le chapitre.

```quiz
title: Choisir son outil — validation
tracksProgress: true
submitMode: last-only
questions:
  - prompt: Une équipe de trois personnes gère vingt serveurs, sans exigence d'audit. Elle veut que la configuration soit réappliquée chaque nuit, et utilise déjà GitLab. Quel choix est le plus adapté ?
    answers:
      - "Ansible Automation Platform"
      - "Un pipeline GitLab CI planifié chaque nuit, qui lance le playbook"
      - "Ascender sur un cluster Kubernetes dédié"
      - "ansible-playbook lancé à la main chaque matin"
    correct: 2
    explanation: |
      La CI existe déjà, sait planifier et garder la passphrase dans une variable masquée. Une
      plateforme serait disproportionnée ; un lancement manuel n'est pas fiable.
  - prompt: Mille machines éphémères démarrent et s'arrêtent toute la journée, derrière un NAT, sans accès SSH entrant. Comment les configurer ?
    answers:
      - "Un contrôleur qui se connecte en SSH à chaque machine"
      - "ansible-pull au démarrage de chaque machine, puis en cron, avec -s pour étaler les accès au dépôt"
      - "ansible-playbook depuis un poste"
      - "Semaphore avec un inventaire statique"
    correct: 2
    explanation: |
      Sans SSH entrant, seul le pull fonctionne : chaque machine tire sa configuration.
      L'option -s évite que toutes clonent le dépôt à la même seconde.
  - prompt: L'équipe d'exploitation veut un bouton pour relancer un playbook de redémarrage, sans terminal, et un historique des lancements. Pas de Kubernetes dans l'entreprise. Quel choix ?
    answers:
      - "Semaphore UI, en un compose.yml"
      - "AWX, qui exige un cluster"
      - "ansible-navigator en mode interactif"
      - "Event-Driven Ansible"
    correct: 1
    explanation: |
      Semaphore offre l'interface, l'historique et les identifiants stockés, sans cluster.
  - prompt: Une banque doit prouver, en audit, qui a lancé quel playbook sur quel inventaire, avec des droits par équipe, et exige un support éditeur. Quel choix ?
    answers:
      - "Semaphore UI"
      - "Ansible Automation Platform, ou Ascender avec l'offre Pro de CIQ"
      - "ansible-pull"
      - "AWX 24.6.1 sans support"
    correct: 2
    explanation: |
      Droits fins, audit et support : c'est le terrain des plateformes commerciales. Un AWX figé,
      sans support, ne répond pas à l'exigence.
  - prompt: Un service web tombe parfois la nuit ; la supervision envoie alors une alerte. On veut le relancer automatiquement, sans attendre le prochain planning. Quel mécanisme ?
    answers:
      - "Un planning toutes les minutes"
      - "Un rulebook Event-Driven Ansible qui écoute les alertes et lance le playbook de redémarrage"
      - "ansible-pull avec -o"
      - "Un artifact de navigator"
    correct: 2
    explanation: |
      Réagir à un événement au moment où il survient, c'est le rôle d'EDA. Un planning à la
      minute rejouerait tout, tout le temps, pour rien.
  - prompt: Deux développeurs obtiennent des résultats différents avec le même playbook, à cause de versions de collections différentes. Que faut-il en priorité ?
    answers:
      - "Une plateforme avec des droits fins"
      - "Un execution environment commun, épinglé dans ansible-navigator.yml"
      - "ansible-pull"
      - "Un planning nocturne"
    correct: 2
    explanation: |
      Le problème est la reproductibilité. Une image d'EE commune fige ansible-core, les
      collections et les bibliothèques pour tout le monde.
  - prompt: Une entreprise exploite AWX 24.6.1 depuis trois ans, sans souscription. Quelles pistes sont raisonnables pour la suite ? (plusieurs réponses)
    answers:
      - "Migrer vers Ascender, qui reprend l'opérateur et les objets d'AWX"
      - "Passer à Ansible Automation Platform avec une souscription Red Hat"
      - "Rester sur AWX 24.6.1 indéfiniment sans surveiller la suite"
      - "Suivre l'annonce d'une nouvelle version d'AWX après la refonte, en préparant un plan B"
    correct: [1, 2, 4]
    explanation: |
      Les trois pistes actives se défendent selon le budget et le besoin de support. Rester figé
      sans surveillance, c'est accumuler une dette de sécurité.
```
