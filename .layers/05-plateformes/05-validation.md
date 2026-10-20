---
title: "Quiz du chapitre"
description: "Valider le chapitre, que vous ayez fait le cas pratique ou non"
---

## Quiz du chapitre

Ce quiz valide le chapitre. Il ne demande d'avoir réalisé aucun des deux cas pratiques : tout ce
qu'il interroge est expliqué dans la présentation, ou dans le texte et les captures des étapes AWX et
Ascender.


```quiz
title: AWX, Tower, AAP et Ascender — validation
tracksProgress: true
submitMode: last-only
questions:
  - prompt: Une entreprise utilise encore AWX 24.6.1 en production. Quelle est la description la plus juste de sa situation en 2026 ?
    answers:
      - "AWX est abandonné et son code supprimé"
      - "Sa version est figée depuis juillet 2024 : la refonte est annoncée terminée, mais aucune nouvelle version n'est publiée"
      - "AWX a été renommé Ascender"
      - "AWX publie une version par mois"
    correct: 2
    explanation: |
      Les sorties d'AWX sont suspendues depuis juillet 2024. Rien ne casse du jour au lendemain,
      mais plus aucun correctif n'arrive : il faut préparer la suite (AAP, Ascender, ou attendre
      une nouvelle version).
  - prompt: Qu'est devenu Ansible Tower ?
    answers:
      - "Il a été renommé automation controller, dans Red Hat Ansible Automation Platform"
      - "Il a été arrêté et remplacé par AWX, sans plus aucune version commerciale"
      - "Il a été racheté par CIQ"
      - "Il existe toujours sous ce nom, avec un support Red Hat"
    correct: 1
    explanation: |
      Avec AAP 2, Tower devient l'automation controller. AWX en est l'amont libre depuis 2017.
  - prompt: Pourquoi la ressource déployée pour Ascender est-elle de type AWX ?
    answers:
      - "Par erreur de configuration"
      - "Parce que l'opérateur d'Ascender est celui d'AWX, repris par CIQ, qui garde ses types de ressources"
      - "Parce qu'Ascender installe AWX à côté"
      - "Parce que Kubernetes impose ce nom"
    correct: 2
    explanation: |
      Ascender est un dérivé d'AWX, opérateur compris. C'est ce qui rend la migration directe.
  - prompt: Quels besoins une plateforme comme Ascender ou AAP couvre-t-elle de façon plus complète que Semaphore ? (plusieurs réponses)
    answers:
      - "Des droits fins par organisation et par équipe"
      - "L'audit des actions (Activity Stream)"
      - "Une installation sans Kubernetes ni base de données"
      - "Des workflows qui enchaînent plusieurs templates"
    correct: [1, 2, 4]
    explanation: |
      Ces plateformes apportent droits, audit et workflows ; en échange, elles demandent un
      cluster (ou l'installeur de l'éditeur) et une base.
  - prompt: Dans le montage AWX en Docker Compose, pourquoi le conteneur receptor contient-il podman ?
    answers:
      - "Pour remplacer Docker Compose"
      - "Parce qu'hors Kubernetes, AWX lance chaque job dans un conteneur d'execution environment avec podman"
      - "Pour héberger la base de données"
      - "Parce que l'interface web en a besoin"
    correct: 2
    explanation: |
      Sur Kubernetes, un job devient un pod ; ailleurs, ansible-runner le démarre dans un conteneur
      d'EE avec podman. Le receptor joue alors le rôle d'un nœud d'exécution.
  - prompt: Qu'est-ce qu'un nœud AWX de type hybrid ?
    answers:
      - "Un nœud qui pilote les jobs et les exécute aussi"
      - "Un nœud installé à moitié sur Kubernetes"
      - "Un nœud de base de données"
      - "Un nœud réservé à Event-Driven Ansible"
    correct: 1
    explanation: |
      Un nœud control pilote, un nœud execution exécute, un nœud hybrid fait les deux : c'est le
      cas du service task dans le montage Compose.
  - prompt: Dans AWX, que permet le rôle Execute donné à un utilisateur sur un template ?
    answers:
      - "Lancer le template, sans pouvoir le modifier, ni ouvrir le projet, l'inventaire ou les identifiants"
      - "Modifier le template et ses identifiants"
      - "Administrer toute l'organisation"
      - "Lire le mot de passe des identifiants utilisés par le template"
    correct: 1
    explanation: |
      Les rôles AWX portent sur un objet précis. Execute donne le lancement, et seulement lui :
      c'est ainsi qu'on délègue un job sans exposer les secrets.
  - prompt: Pourquoi faut-il remplir « Paths to expose to isolated jobs » pour viser des conteneurs avec le plugin docker_api ?
    answers:
      - "Parce que chaque job tourne dans son propre conteneur, qui ne voit pas le socket Docker de l'hôte sans ce réglage"
      - "Pour installer la collection community.docker"
      - "Pour ouvrir le port SSH des cibles"
      - "Pour donner les droits Execute à l'opérateur"
    correct: 1
    explanation: |
      Le conteneur du job est isolé. Ce réglage d'admin y monte des chemins de l'hôte, ici le
      socket de Docker ; il donne des droits root sur Docker, à n'accorder qu'en connaissance de cause.
  - prompt: Où s'exécute un job lancé depuis Ascender ?
    answers:
      - "Sur votre poste"
      - "Dans un pod créé depuis l'image d'execution environment"
      - "Dans le pod de la base de données"
      - "Directement sur le nœud minikube, hors conteneur"
    correct: 2
    explanation: |
      Chaque job tourne dans un conteneur issu de l'EE : c'est la notion du chapitre 2.
  - prompt: Que fait Event-Driven Ansible qu'un planning ne fait pas ?
    answers:
      - "Il lance un playbook au moment où un événement survient, par exemple une alerte"
      - "Il remplace les inventaires"
      - "Il chiffre les secrets"
      - "Il rend les playbooks idempotents"
    correct: 1
    explanation: |
      Un planning suit l'horloge ; un rulebook EDA réagit à un événement, selon des règles.
```
