---
title: "Un premier run avec navigator"
description: "Installer navigator, lancer un playbook en stdout puis en mode interactif, rejouer un artifact"
---

## Installer navigator

navigator est un paquet Python. Pour ne rien installer de global sur votre poste, vous allez le
mettre dans un **environnement virtuel** Python, dans le dossier `atelier/navigator/venv/`. Le bloc
ci-dessous vérifie d'abord votre version de Python, puis crée l'environnement et installe navigator,
en version épinglée. Comptez une à deux minutes.

```exec
label: Installer ansible-navigator dans un venv
---
# navigator 26.10 installe ansible-core 2.21, qui exige Python 3.12 ou plus récent
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)'; then
  echo "Python 3.12 ou plus récent est nécessaire (vous avez : $(python3 --version))"
  exit 0
fi

mkdir -p atelier/navigator
python3 -m venv atelier/navigator/venv
atelier/navigator/venv/bin/pip install --quiet ansible-navigator==26.10.0 \
  || { echo "Installation impossible : vérifiez votre connexion"; exit 0; }
atelier/navigator/venv/bin/ansible-navigator --version
```

Le bloc se termine par `ansible-navigator 26.10.0`. Le paquet a installé bien plus que navigator :
`ansible-core`, mais aussi `ansible-lint` (l'analyse de qualité des playbooks) et `ansible-builder`
(la construction d'execution environments).

Le venv n'est pas « activé » : toutes les commandes de ce chapitre commencent donc par
`PATH="$PWD/atelier/navigator/venv/bin:$PATH"`, qui place le dossier `bin/` du venv en tête du
chemin de recherche, le temps de la commande. Ce n'est pas un détail : avec `--ee false`, navigator
lance `ansible-playbook` **depuis le PATH**. Sans ce préfixe, il échouerait sur un poste sans
Ansible, ou utiliserait en silence un autre Ansible installé ailleurs.

> 📖 [Installer ansible-navigator](https://docs.ansible.com/projects/navigator/installation/)

```verify
nav=atelier/navigator/venv/bin/ansible-navigator
if [ ! -x "$nav" ]; then echo "absent : $nav (lancez le bloc ci-dessus)"; exit 1; fi
v=$("$nav" --version 2>/dev/null)
case "$v" in
  "ansible-navigator 26."*) echo "installé : $v" ;;
  *) echo "$nav ne répond pas comme attendu : « $v »"; exit 1 ;;
esac
```

```hint
`No module named venv` (Debian, Ubuntu, WSL) : le module venv est un paquet séparé. Installez-le
avec `sudo apt install python3-venv`, puis relancez le bloc.
```

## Le playbook de démonstration

Le playbook de ce chapitre est fourni dans le dépôt, dans
[lab/navigator/site.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/navigator/site.yml) :
un seul play, sur la machine locale, avec une seule tâche `debug` qui affiche « Bonjour depuis
ansible-navigator ». Copiez-le dans votre atelier :

```exec
label: Copier le playbook
---
cp lab/navigator/site.yml atelier/navigator/site.yml && echo "copié dans atelier/navigator/site.yml"
```

```verify
if [ -f atelier/navigator/site.yml ]; then echo "trouvé : atelier/navigator/site.yml"; else echo "absent : atelier/navigator/site.yml"; exit 1; fi
```

## Un premier run en mode stdout

Lancez le playbook en mode **stdout**, sans execution environment. Les deux options se lisent
ainsi : `--mode stdout` pour une sortie classique, `--ee false` pour utiliser l'Ansible du venv
plutôt qu'une image.

```exec
label: ansible-navigator run (stdout)
---
PATH="$PWD/atelier/navigator/venv/bin:$PATH" ansible-navigator run atelier/navigator/site.yml --mode stdout --ee false
```

La sortie est exactement celle d'`ansible-playbook` :

```text
TASK [Dire bonjour] ************************************************************
ok: [localhost] => {
    "msg": "Bonjour depuis ansible-navigator"
}

PLAY RECAP *********************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=0    skipped=0    ...
```

Deux fichiers sont pourtant apparus. À côté du playbook, un **artifact**
`atelier/navigator/site-artifact-<date>.json` enregistre toute l'exécution. Et à la racine du
dépôt, `ansible-navigator.log` est le journal de navigator lui-même ; il est ignoré par git.

```verify
n=$(ls atelier/navigator/site-artifact-*.json 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" -ge 1 ]; then echo "$n artifact(s) dans atelier/navigator/"; else echo "aucun artifact dans atelier/navigator/ : lancez le run"; exit 1; fi
```

## L'interface en mode texte

Relancez le même playbook **sans** `--mode stdout` : navigator ouvre son interface en mode texte
dans le terminal.

```exec
label: ansible-navigator run (interactif)
---
PATH="$PWD/atelier/navigator/venv/bin:$PATH" ansible-navigator run atelier/navigator/site.yml --ee false
```

Cliquez dans le terminal pour lui donner le clavier, puis parcourez l'exécution :

| Touche | Effet |
|---|---|
| `0` | descendre dans le play n° 0, puis dans la tâche n° 0 |
| `Échap` | remonter d'un niveau |
| `:help` | afficher l'aide |
| `:q` | quitter navigator |

Vous retrouvez les trois écrans de l'étape précédente : les plays, les tâches, puis le détail
complet de la tâche `Dire bonjour`. Quittez avec `:q` avant de passer à la suite.

```acknowledge
J'ai parcouru l'exécution dans l'interface, puis quitté avec :q
```

## Rejouer un artifact

Un artifact se **rejoue** dans l'interface, sans rien réexécuter : c'est le moyen de relire une
exécution passée, ou d'en envoyer une à un collègue pour qu'il l'examine. La commande ci-dessous
ouvre le plus récent :

```exec
label: ansible-navigator replay
---
PATH="$PWD/atelier/navigator/venv/bin:$PATH" ansible-navigator replay "$(ls -t atelier/navigator/site-artifact-*.json | head -1)" --ee false
```

L'écran est le même qu'après le run, alors qu'aucune tâche n'a tourné. Quittez avec `:q`.

```acknowledge
J'ai rejoué un artifact
```

## Un fichier de configuration

Taper `--mode stdout --ee false` à chaque fois devient lassant. navigator lit ses réglages dans un
fichier **`ansible-navigator.yml`**, cherché dans le dossier courant, ou désigné par la variable
d'environnement `ANSIBLE_NAVIGATOR_CONFIG`. Créez `atelier/navigator/ansible-navigator.yml` :

```yaml
---
ansible-navigator:
  mode: stdout
  execution-environment:
    enabled: false
  playbook-artifact:
    save-as: "{playbook_dir}/artefacts/{playbook_name}-{time_stamp}.json"
```

Ce fichier fixe le mode, désactive l'execution environment et range les artifacts dans un
sous-dossier `artefacts/`. Lancez le playbook en désignant le fichier, et **sans** option :

```exec
label: ansible-navigator run (avec le fichier de configuration)
---
ANSIBLE_NAVIGATOR_CONFIG=atelier/navigator/ansible-navigator.yml PATH="$PWD/atelier/navigator/venv/bin:$PATH" ansible-navigator run atelier/navigator/site.yml
```

La sortie est en mode stdout, sans image, et le nouvel artifact est dans
`atelier/navigator/artefacts/`. Dans un projet, on commite ce fichier à la racine du dépôt : toute
l'équipe partage alors les mêmes réglages, y compris l'image d'execution environment à utiliser.

> 📖 [Les réglages de navigator](https://docs.ansible.com/projects/navigator/settings/)

```verify
if ls atelier/navigator/artefacts/site-*.json >/dev/null 2>&1; then
  echo "artifact rangé dans atelier/navigator/artefacts/ : le fichier de configuration est pris en compte"
else
  echo "aucun artifact dans atelier/navigator/artefacts/ : vérifiez le fichier et la variable ANSIBLE_NAVIGATOR_CONFIG"
  exit 1
fi
```

## En option : dans un vrai execution environment

Cette section télécharge l'image d'execution environment par défaut,
`ghcr.io/ansible/community-ansible-dev-tools`, soit environ **500 Mo** sur le disque. Elle est facultative.

navigator utilise Podman par défaut s'il le trouve ; l'option `--ce docker` (*container engine*)
lui demande d'utiliser Docker, et `--pp missing` (*pull policy*) de ne télécharger l'image que si
elle manque.

```exec
label: ansible-navigator run dans un EE
---
PATH="$PWD/atelier/navigator/venv/bin:$PATH" ansible-navigator run atelier/navigator/site.yml --mode stdout --ce docker --pp missing
```

Le résultat est le même, mais cette fois `ansible-core` et ses collections viennent de l'image, et
non plus de votre venv : la même commande donnerait le même résultat sur n'importe quel poste muni
de Docker. Pour libérer la place ensuite : `docker image rm ghcr.io/ansible/community-ansible-dev-tools:latest`.

L'image est désignée ici par `latest`, pour la démonstration. En équipe, il vaut mieux l'épingler
(une version précise, ou un *digest* `@sha256:…`) dans `ansible-navigator.yml`, sous
`execution-environment.image` : sans cela, deux postes peuvent exécuter deux images différentes,
ce qui annule l'intérêt des execution environments.

## Quiz du chapitre

Ce quiz valide le chapitre.

```quiz
title: ansible-navigator — validation
tracksProgress: true
submitMode: last-only
questions:
  - prompt: Que fait l'option --ee false ?
    answers:
      - "Elle désactive l'interface en mode texte"
      - "Elle exécute le playbook avec l'Ansible installé localement, sans image de conteneur"
      - "Elle supprime l'image d'execution environment"
      - "Elle désactive les artifacts"
    correct: 2
    explanation: |
      `--ee false` désactive l'execution environment : navigator utilise alors l'ansible-core de
      votre environnement, comme ansible-playbook.
  - prompt: À quoi sert un artifact de navigator ?
    answers:
      - "À rejouer l'exécution dans l'interface, sans rien réexécuter"
      - "À relancer automatiquement le playbook en cas d'échec"
      - "À stocker les secrets de l'exécution"
      - "À construire une image d'execution environment"
    correct: 1
    explanation: |
      L'artifact enregistre tout le résultat d'une exécution. `ansible-navigator replay` l'affiche
      comme si elle venait de se terminer.
  - prompt: Quel outil construit une image d'execution environment ?
    answers:
      - "ansible-galaxy"
      - "ansible-builder"
      - "ansible-lint"
      - "ansible-pull"
    correct: 2
    explanation: |
      ansible-builder lit un fichier execution-environment.yml (image de base, collections,
      paquets Python) et produit une image.
  - prompt: Pourquoi commiter un fichier ansible-navigator.yml à la racine d'un projet ? (plusieurs réponses)
    answers:
      - "Pour que toute l'équipe partage les mêmes réglages"
      - "Pour fixer l'image d'execution environment utilisée"
      - "Pour y ranger les mots de passe du projet"
      - "Pour éviter de répéter les options à chaque commande"
    correct: [1, 2, 4]
    explanation: |
      Le fichier partage le mode, l'image, le rangement des artifacts. Les secrets n'y ont pas
      leur place.
  - prompt: Avec un EE, un playbook dépose un fichier sur localhost. Où se trouve le fichier après l'exécution ?
    answers:
      - "Sur votre poste, dans /tmp"
      - "Nulle part : il était dans le conteneur de l'EE, supprimé à la fin de l'exécution"
      - "Dans l'artifact"
      - "Sur la première machine de l'inventaire"
    correct: 2
    explanation: |
      Dans un EE, `localhost` est le conteneur. Pour agir sur votre poste depuis un EE, il faut le
      viser comme une machine distante.
```
