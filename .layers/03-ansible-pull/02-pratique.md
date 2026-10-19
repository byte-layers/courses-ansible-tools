---
title: "Une machine qui se configure seule"
description: "Un dépôt git local, une machine en conteneur, un changement voulu, une dérive"
---

## Le dépôt surveillé

La machine va tirer sa configuration d'un dépôt git. Pour que l'exercice tourne sans réseau, ce
sera un dépôt **local**, dans `atelier/pull/repo/`, que vous monterez dans le conteneur. Créez d'abord
le dossier :

```exec
label: Créer atelier/pull/repo
---
mkdir -p atelier/pull/repo && echo "dossier créé"
```

Créez ensuite le playbook `atelier/pull/repo/site.yml`. Il dépose un fichier `/etc/motd-layers`
dont le contenu indique la version de la configuration :

🚧 **À compléter** — `atelier/pull/repo/site.yml`

```yaml
- name: Configuration tirée par ansible-pull
  hosts: localhost
  connection: local            # ansible-pull applique le playbook à la machine elle-même
  gather_facts: false
  tasks:
    - name: Déposer le fichier de configuration
      ansible.builtin.copy:
        content: "version 1\n"
        dest:                  # TODO : /etc/motd-layers
        mode: "0644"
```

Un dossier n'est pas un dépôt : ansible-pull **clone** son URL avec git, il faut donc un vrai
dépôt, avec au moins un commit. Le bloc ci-dessous l'initialise. Il passe une identité git sur la
ligne de commande (`-c user.name=…`), pour fonctionner même si git n'est pas configuré sur votre
poste.

```exec
label: Initialiser le dépôt et faire le premier commit
---
git -C atelier/pull/repo init -q -b main
git -C atelier/pull/repo add site.yml
git -C atelier/pull/repo -c user.name=atelier -c user.email=atelier@example.com commit -qm "version 1"
git -C atelier/pull/repo log --oneline
```

```hint
Le chemin du fichier se met directement après `dest:`, sur la même ligne : `dest: /etc/motd-layers`.
```

```verify
r=atelier/pull/repo
if [ ! -f "$r/site.yml" ]; then echo "absent : $r/site.yml"; exit 1; fi
if ! grep -q 'dest: */etc/motd-layers' "$r/site.yml"; then echo "le dest de la tâche doit être /etc/motd-layers"; exit 1; fi
if ! git -C "$r" rev-parse HEAD >/dev/null 2>&1; then echo "$r n'est pas un dépôt git avec un commit : lancez le bloc ci-dessus"; exit 1; fi
if [ -n "$(git -C "$r" status --porcelain)" ]; then echo "$r a des modifications non commitées : ansible-pull ne verra que le dernier commit"; exit 1; fi
echo "dépôt prêt : $(git -C "$r" log --oneline -1)"
```

## L'image de la machine

La « machine » est un conteneur construit depuis
[lab/pull/Dockerfile](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/pull/Dockerfile) :
une image `python:3.12-slim` à laquelle on ajoute **git** et **ansible-core**, rien d'autre. Ni
serveur SSH, ni agent : c'est tout ce dont ansible-pull a besoin. Une ligne de configuration git
(`safe.directory`) autorise en plus le clonage d'un dépôt qui appartient à un autre utilisateur :
c'est le cas, sous Linux, de votre dépôt monté dans le conteneur, et git refuserait sinon de le
lire. Construisez-la (une trentaine de
secondes la première fois) :

```exec
label: Construire l'image layers-ansible-pull
---
docker build -q -t layers-ansible-pull:1 lab/pull && echo "image layers-ansible-pull:1 construite"
```

```verify
if docker image inspect layers-ansible-pull:1 >/dev/null 2>&1; then echo "image layers-ansible-pull:1 présente"; else echo "image absente : lancez le bloc ci-dessus"; exit 1; fi
```

## Démarrer la machine

Démarrez le conteneur `layers-pull1`. Il monte votre dépôt en **lecture seule** sur `/repo`, et sa
commande est une boucle qui joue le rôle de cron : `ansible-pull`, puis 30 secondes d'attente, et
on recommence.

```exec
label: Démarrer layers-pull1
---
# Le montage exige un chemin absolu : $PWD est la racine du dépôt du cours
docker run -d --name layers-pull1 -v "$PWD/atelier/pull/repo:/repo:ro" layers-ansible-pull:1 \
  sh -c 'while true; do echo "=== $(date +%T)"; ansible-pull -U /repo -d /var/lib/ansible-pull site.yml; sleep 30; done' \
  >/dev/null && echo "layers-pull1 démarré"
```

Attendez une dizaine de secondes, puis lisez son journal : la machine a cloné le dépôt et s'est
appliqué le playbook. L'ordre des lignes peut varier, mais vous y trouverez celles-ci :

```exec
label: Journal de layers-pull1
---
docker logs --tail 12 layers-pull1
```

```text
[WARNING]: Could not match supplied host pattern, ignoring: 3f2c1a9e8b7d
TASK [Déposer le fichier de configuration] *************************************
changed: [localhost]
```

L'avertissement est normal : ansible-pull limite l'exécution au **nom de la machine** (ici l'identifiant
du conteneur) et à `localhost` ; le playbook ne vise que `localhost`, le nom est donc ignoré.

```verify
c=layers-pull1
if [ "$(docker container inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" != "true" ]; then echo "$c ne tourne pas : lancez le bloc « Démarrer layers-pull1 »"; exit 1; fi
v=$(docker exec "$c" cat /etc/motd-layers 2>/dev/null)
if [ "$v" = "version 1" ]; then echo "$c s'est configurée seule : /etc/motd-layers contient « version 1 »"
else echo "/etc/motd-layers ne contient pas encore « version 1 » (contenu : « $v ») : attendez un cycle de 30 s, puis relisez le journal"; exit 1; fi
```

## Un changement voulu

Modifiez maintenant l'état voulu : dans `atelier/pull/repo/site.yml`, remplacez `version 1` par
`version 2`. Puis commitez, car ansible-pull ne voit que ce qui est **commité** :

```exec
label: Commiter la version 2
---
git -C atelier/pull/repo -c user.name=atelier -c user.email=atelier@example.com commit -qam "version 2" && git -C atelier/pull/repo log --oneline -1
```

Vous n'avez rien lancé sur la machine. Au cycle suivant, dans les 30 secondes, elle tire le nouveau
commit et s'applique la version 2. C'est le **pull** : l'initiative vient de la machine.

```verify
v=$(docker exec layers-pull1 cat /etc/motd-layers 2>/dev/null)
if [ "$v" = "version 2" ]; then echo "la machine a tiré le commit : « version 2 »"
else echo "contenu actuel : « $v ». Le commit est-il fait (git log) ? Sinon, attendez un cycle de 30 s"; exit 1; fi
```

## Une dérive

Simulez une intervention manuelle sur la machine : supprimez le fichier, sans toucher au dépôt.

```exec
label: Supprimer le fichier à la main
---
# On note l'heure de la suppression, pour que la vérification sache que le fichier a été recréé après
docker exec layers-pull1 rm -f /etc/motd-layers && date +%s > atelier/pull/.derive-pull1 && echo "fichier supprimé dans layers-pull1"
```

Le dépôt n'a pas changé, et pourtant, au cycle suivant, ansible-pull rejoue le playbook, qui
**recrée** le fichier. La dérive est corrigée sans intervention : c'est la **réconciliation
continue**.

```verify
if [ ! -f atelier/pull/.derive-pull1 ]; then echo "la dérive n'a pas encore été simulée : lancez le bloc ci-dessus"; exit 1; fi
t=$(cat atelier/pull/.derive-pull1)
m=$(docker exec layers-pull1 stat -c %Y /etc/motd-layers 2>/dev/null)
if [ -z "$m" ]; then echo "le fichier n'est pas encore revenu : attendez un cycle de 30 s"; exit 1; fi
if [ "$m" -lt "$t" ]; then echo "le fichier date d'avant la suppression : relancez le bloc de suppression"; exit 1; fi
echo "dérive corrigée : /etc/motd-layers a été recréé après la suppression"
```

## Le piège de -o

L'option `-o` (`--only-if-changed`) semble une bonne idée : ne rejouer le playbook que si le dépôt
a changé, pour économiser des exécutions. Démarrez une seconde machine, `layers-pull2`, avec cette
option :

```exec
label: Démarrer layers-pull2 (avec -o)
---
docker run -d --name layers-pull2 -v "$PWD/atelier/pull/repo:/repo:ro" layers-ansible-pull:1 \
  sh -c 'while true; do ansible-pull -o -U /repo -d /var/lib/ansible-pull site.yml; sleep 30; done' \
  >/dev/null && echo "layers-pull2 démarré"
```

Attendez son premier passage (une dizaine de secondes) : elle applique la version 2, comme
`layers-pull1`. Supprimez ensuite le fichier sur cette machine :

```exec
label: Supprimer le fichier sur layers-pull2
---
docker exec layers-pull2 rm -f /etc/motd-layers && date +%s > atelier/pull/.derive-pull2 && echo "fichier supprimé dans layers-pull2"
```

Attendez un cycle de 30 secondes, puis lisez son journal :

```exec
label: Journal de layers-pull2
---
docker logs --tail 3 layers-pull2; echo "---"; docker exec layers-pull2 cat /etc/motd-layers || true
```

Le fichier ne revient **pas**. Le journal dit pourquoi : à chaque cycle depuis le premier, ansible-pull
écrit `Repository has not changed, quitting` et s'arrête avant de lancer le playbook.
Avec `-o`, ansible-pull compare le commit du dépôt au dernier qu'il a vu, et ne regarde jamais
l'état de la machine. Une dérive sans commit passe donc inaperçue.

| Mode | Un nouveau commit | Une dérive, sans commit |
|---|---|---|
| sans `-o` (à chaque cycle) | appliqué | **corrigée** |
| avec `-o` (sur commit) | appliqué | **ignorée** |

Il vaut mieux réserver `-o` aux playbooks lourds dont on accepte la dérive, et garder un passage
complet à intervalle régulier, par exemple une fois par nuit, pour la rattraper.

```verify
if [ ! -f atelier/pull/.derive-pull2 ]; then echo "le fichier de layers-pull2 n'a pas encore été supprimé : lancez le bloc de suppression"; exit 1; fi
t=$(cat atelier/pull/.derive-pull2); now=$(date +%s)
if [ $((now - t)) -lt 35 ]; then echo "attendez au moins un cycle complet (30 s) après la suppression, puis vérifiez à nouveau"; exit 1; fi
if docker exec layers-pull2 test -f /etc/motd-layers; then echo "le fichier est revenu dans layers-pull2 : la machine tourne-t-elle bien avec -o ?"; exit 1; fi
if ! docker logs layers-pull2 2>&1 | grep -q 'Repository has not changed'; then echo "le journal de layers-pull2 ne montre aucun cycle sauté"; exit 1; fi
echo "avec -o, la dérive est restée : « Repository has not changed », fichier toujours absent"
```

## Nettoyer

Supprimez les deux machines, et les deux fichiers d'horodatage des vérifications. L'image
`layers-ansible-pull:1` peut rester ; pour la retirer aussi : `docker image rm layers-ansible-pull:1`.

```exec
label: Supprimer layers-pull1 et layers-pull2
---
docker rm -f layers-pull1 layers-pull2 && rm -f atelier/pull/.derive-pull1 atelier/pull/.derive-pull2
```

```verify
for c in layers-pull1 layers-pull2; do
  if docker container inspect "$c" >/dev/null 2>&1; then echo "$c existe encore : lancez le bloc ci-dessus"; exit 1; fi
done
echo "layers-pull1 et layers-pull2 supprimés"
```

## Quiz du chapitre

Ce quiz valide le chapitre.

```quiz
title: ansible-pull — validation
tracksProgress: true
submitMode: last-only
questions:
  - prompt: Pourquoi le dépôt devait-il être un vrai dépôt git avec un commit ?
    answers:
      - "Parce qu'ansible-pull clone l'URL avec git et ne voit que ce qui est commité"
      - "Parce que Docker refuse de monter un dossier qui n'est pas un dépôt"
      - "Parce qu'ansible-core exige un dossier .git pour lire un playbook"
      - "Ce n'était pas nécessaire"
    correct: 1
    explanation: |
      ansible-pull fait un clone ou une mise à jour git. Une modification non commitée n'existe
      pas pour lui.
  - prompt: Que faut-il installer sur chaque machine pour utiliser ansible-pull ?
    answers:
      - "Un serveur SSH"
      - "git et Ansible"
      - "Un agent propriétaire"
      - "Docker"
    correct: 2
    explanation: |
      L'image de l'exercice ne contenait que Python, git et ansible-core. Docker ne servait qu'à
      simuler la machine.
  - prompt: Vous supprimez un fichier géré sur une machine en ansible-pull sans -o. Que se passe-t-il ?
    answers:
      - "Rien jusqu'au prochain commit"
      - "Le fichier est recréé au cycle suivant"
      - "ansible-pull signale une erreur"
      - "Le dépôt est mis à jour"
    correct: 2
    explanation: |
      Sans `-o`, le playbook est rejoué à chaque cycle et corrige la dérive.
  - prompt: Même question avec -o.
    answers:
      - "Le fichier est recréé au cycle suivant"
      - "Le fichier n'est pas recréé : ansible-pull voit que le dépôt n'a pas changé et s'arrête"
      - "La machine est réinstallée"
      - "ansible-pull échoue"
    correct: 2
    explanation: |
      `-o` compare le commit, pas l'état de la machine : « Repository has not changed, quitting ».
  - prompt: Quels sont des avantages d'un contrôleur comme Semaphore par rapport à ansible-pull ? (plusieurs réponses)
    answers:
      - "Un historique central des exécutions"
      - "Aucune infrastructure à héberger"
      - "Des secrets stockés une seule fois"
      - "Ansible n'a pas besoin d'être installé sur chaque machine"
    correct: [1, 3, 4]
    explanation: |
      Le contrôleur centralise l'exécution, l'historique et les secrets, au prix d'un service à
      héberger. ansible-pull, lui, n'en demande aucun.
```
