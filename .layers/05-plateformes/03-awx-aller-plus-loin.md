---
title: "Aller plus loin avec AWX"
description: "En 1 h 30 : ce qu'un admin sys doit savoir, puis des conteneurs en cible, un questionnaire, un opérateur aux droits limités, un planning et l'audit"
---

## Le programme

Cette étape prolonge la précédente, sur le **même AWX**, toujours allumé. Elle dure environ
**1 h 30** :

| Partie | Durée | Ce que vous faites |
|---|---|---|
| Ce qu'un admin sys doit savoir | 15 min | lire un résumé, et repérer chaque point dans l'interface |
| 1. Des conteneurs en cible | 30 min | configurer deux conteneurs avec le plugin de connexion Docker, comme dans le cours « premiers pas » |
| 2. Un questionnaire | 15 min | faire saisir une valeur au lancement du job |
| 3. Un opérateur | 20 min | créer un utilisateur qui peut lancer le job, et rien d'autre |
| 4. Planifier et auditer | 10 min | un planning, puis le journal de qui a fait quoi |

Vérifiez d'abord qu'AWX répond toujours :

```verify
v=$(curl -sf --max-time 3 http://127.0.0.1:28052/api/v2/ping/ 2>/dev/null | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["version"])' 2>/dev/null)
if [ -n "$v" ]; then echo "AWX $v répond sur 127.0.0.1:28052"
else echo "AWX ne répond pas : redémarrez-le avec l'étape précédente (« Démarrer AWX »)"; exit 1; fi
```

## Ce qu'un admin sys doit savoir

Utiliser AWX, c'est cliquer sur « Launch ». L'**administrer**, c'est garantir qu'il tourne, qu'il
est sûr, et qu'on peut le reconstruire. Huit sujets reviennent toujours ; la dernière colonne dit où
les voir dans votre AWX.

| Sujet | Ce qu'il faut savoir | Où le voir |
|---|---|---|
| **Installation et mises à jour** | l'opérateur Kubernetes est la seule voie supportée ; une mise à jour change la version de l'opérateur, qui joue les migrations | (le montage Compose de ce cours n'en a pas) |
| **Sauvegarde** | la base PostgreSQL **et** la `SECRET_KEY` : sans elle, les identifiants de la base sont illisibles | `atelier/awx/config/SECRET_KEY` |
| **Execution environments** | l'image qui exécute les jobs ; on construit les siennes avec ansible-builder et on les épingle | **Administration > Execution Environments** |
| **Capacité** | chaque instance accepte un nombre de tâches simultanées ; on la répartit en groupes d'instances | **Administration > Instances** et **Instance Groups** |
| **Droits** | organisations, équipes, et des rôles par objet : on peut **utiliser** un identifiant ou un template sans pouvoir le **lire** ni le modifier | **Access** ; partie 3 ci-dessous |
| **Identifiants** | stockés chiffrés ; en entreprise, on les lit plutôt dans un coffre externe (HashiCorp Vault, CyberArk…) | **Resources > Credentials** |
| **Audit et journaux** | l'Activity Stream trace les actions ; les journaux des jobs partent vers un outil central (ELK, Splunk…) | **Views > Activity Stream** ; partie 4 |
| **Hygiène** | des tâches de nettoyage purgent les vieux jobs et le journal, sinon la base grossit sans fin | **Administration > Management Jobs** |

Ouvrez **Administration > Management Jobs** : AWX y a créé tout seul des tâches de nettoyage, déjà
planifiées. C'est le genre de détail qu'un admin doit connaître avant que le disque de la base ne
soit plein.

```acknowledge
J'ai repéré ces sujets dans l'interface d'AWX
```

## 1. Des conteneurs en cible

Jusqu'ici, les jobs visaient `localhost`, le conteneur du job lui-même. Visez maintenant de vraies
cibles : deux conteneurs, joints **sans SSH** par l'API Docker, comme dans le cours « premiers
pas ». Trois pièces sont nécessaires, et chacune est une notion d'admin.

**Les cibles.** Démarrez deux conteneurs `python:3.12-slim` qui ne font rien :

```exec
label: Démarrer layers-cible1 et layers-cible2
---
for n in 1 2; do
  if docker container inspect layers-cible$n >/dev/null 2>&1; then
    docker start layers-cible$n >/dev/null && echo "layers-cible$n démarré"
  else
    docker run -d --name layers-cible$n python:3.12-slim sleep infinity >/dev/null && echo "layers-cible$n créé"
  fi
done
```

**Le socket Docker, transmis aux jobs.** Le receptor monte le socket de Docker, mais chaque job
tourne dans **son propre** conteneur, qui ne voit rien de l'hôte par défaut. Il faut l'autoriser,
dans un réglage d'admin : ouvrez **Settings**, puis **Jobs settings**, cliquez sur **Edit**, et dans
**Paths to expose to isolated jobs**, saisissez :

```json
["/var/run/docker.sock"]
```

Enregistrez avec **Save**. Ce réglage est puissant : un job qui accède au socket de Docker a les
droits root sur la machine Docker. En entreprise, on ne l'accorde qu'en connaissance de cause.

**La collection.** Le plugin de connexion `community.docker.docker_api` vient de la collection
`community.docker`, absente de l'image d'EE. AWX sait l'installer seul, à la synchronisation d'un
projet, s'il trouve un fichier `collections/requirements.yml` dans le dépôt : c'est le cas du dépôt
du cours, à partir du tag `v4`
([collections/requirements.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/collections/requirements.yml)).
Ouvrez votre projet `courses-ansible-tools` dans **Resources > Projects**, cliquez sur **Edit**,
remplacez `v1` par **`v4`** dans *Source Control Branch/Tag/Commit*, et enregistrez : le projet se
resynchronise, et installe la collection.

```verify
c=$(mktemp); trap 'rm -f "$c"' EXIT
for n in 1 2; do
  [ "$(docker container inspect -f '{{.State.Running}}' layers-cible$n 2>/dev/null)" = "true" ] || { echo "layers-cible$n ne tourne pas : lancez le bloc ci-dessus"; exit 1; }
done
curl -sf --max-time 5 -u admin:changeme http://127.0.0.1:28052/api/v2/settings/jobs/ > "$c" || { echo "AWX ne répond pas"; exit 1; }
python3 -I -c 'import sys, json; sys.exit(0 if "/var/run/docker.sock" in json.load(open(sys.argv[1]))["AWX_ISOLATION_SHOW_PATHS"] else 1)' "$c" \
  || { echo "le chemin /var/run/docker.sock n'est pas dans « Paths to expose to isolated jobs »"; exit 1; }
curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/projects/?scm_branch=v4&status=successful" > "$c"
python3 -I -c 'import sys, json; sys.exit(0 if json.load(open(sys.argv[1]))["count"] else 1)' "$c" \
  || { echo "aucun projet synchronisé sur le tag v4 : modifiez le projet, puis attendez le statut Successful"; exit 1; }
echo "cibles démarrées, socket exposé aux jobs, projet synchronisé sur v4"
```

**L'inventaire.** Dans **Resources > Inventories**, **Add > Add inventory** : nom `conteneurs`,
organisation `Default`. Dans son onglet **Groups**, ajoutez un groupe `cibles` avec ces
**Variables** :

```yaml
ansible_connection: community.docker.docker_api
ansible_python_interpreter: /usr/local/bin/python3
```

Les variables d'un groupe s'appliquent à tous ses hôtes : chacun sera joint par l'API Docker, avec le
Python de l'image. Dans l'onglet **Hosts** du groupe, ajoutez deux hôtes nommés exactement comme les
conteneurs : `layers-cible1` et `layers-cible2`.

**Le template.** Dans **Resources > Templates**, **Add > Add job template** : nom
`Configurer les cibles`, inventaire `conteneurs`, projet `courses-ansible-tools`, playbook
`lab/awx/playbooks/cibles.yml`. Ce playbook
([lab/awx/playbooks/cibles.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/awx/playbooks/cibles.yml))
dépose dans `/etc/motd-awx` la valeur de la variable `message`, par défaut « Configuré par AWX ».
Enregistrez, puis **Launch**.

Le récapitulatif du job montre les deux cibles en `changed`. Vérifiez depuis votre poste :

```exec
label: Lire le fichier sur les deux cibles
---
for n in 1 2; do echo "layers-cible$n : $(docker exec layers-cible$n cat /etc/motd-awx)"; done
```

```verify
for n in 1 2; do
  v=$(docker exec layers-cible$n cat /etc/motd-awx 2>/dev/null)
  [ -n "$v" ] || { echo "/etc/motd-awx est absent de layers-cible$n : lancez le template « Configurer les cibles »"; exit 1; }
done
echo "les deux cibles ont été configurées par AWX"
```

```hint
`the connection plugin 'community.docker.docker_api' was not found` : la collection n'est pas
installée. Vérifiez que le projet pointe sur `v4` et que sa dernière synchronisation a réussi.
```

```hint
`Error connecting: ... /var/run/docker.sock` : le socket n'est pas transmis au job. Vérifiez le
réglage *Paths to expose to isolated jobs*, enregistré avec les crochets et les guillemets.
```

## 2. Un questionnaire

Un template peut poser des **questions** au lancement : c'est le **survey**. Il permet de confier
un job à quelqu'un qui ne connaît pas Ansible, en ne lui laissant choisir que ce qu'on autorise.

Ouvrez le template `Configurer les cibles`, onglet **Survey**, puis **Add** :

| Champ | Valeur |
|---|---|
| Question | `Quel message déposer ?` |
| Answer variable name | `message` |
| Answer type | `Text` |
| Required | coché |

Enregistrez la question, puis activez le survey avec l'interrupteur en haut de l'onglet. Lancez le
template : AWX vous pose la question. Saisissez un message de votre choix, puis relisez les cibles
avec le bloc de la partie précédente.

```verify
for n in 1 2; do
  v=$(docker exec layers-cible$n cat /etc/motd-awx 2>/dev/null)
  if [ "$v" = "Configuré par AWX" ] || [ -z "$v" ]; then
    echo "layers-cible$n contient encore la valeur par défaut : lancez le template avec le survey activé, et un autre message"; exit 1
  fi
done
echo "les cibles contiennent votre message : $(docker exec layers-cible1 cat /etc/motd-awx)"
```

## 3. Un opérateur aux droits limités

Créez un utilisateur qui pourra **lancer** ce template, et rien d'autre. Dans **Access > Users**,
**Add** : nom d'utilisateur `operateur`, un mot de passe de votre choix, type **Normal User**,
organisation `Default`. Enregistrez.

Ouvrez ensuite le template `Configurer les cibles`, onglet **Access**, **Add** : choisissez
**Users**, cochez `operateur`, puis le rôle **Execute**. Enregistrez.

Ouvrez une fenêtre de navigation privée, connectez-vous en `operateur`, et constatez :

| Ce qu'il voit ou fait | Pourquoi |
|---|---|
| il voit le template `Configurer les cibles`, et seulement lui | le rôle Execute ne porte que sur cet objet |
| il peut le lancer, et répondre au survey | c'est exactement ce que donne Execute |
| il ne voit ni le projet, ni l'inventaire, ni les réglages | aucun rôle ne lui a été donné dessus |
| il ne peut pas modifier le template | il faudrait le rôle Admin sur le template |

Lancez le template en tant qu'`operateur`, avec un message qui le dit, par exemple
« Lancé par l'opérateur ».

```verify
out=$(curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/jobs/?created_by__username=operateur&status=successful") \
  || { echo "AWX ne répond pas"; exit 1; }
n=$(echo "$out" | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["count"])')
if [ "$n" -ge 1 ]; then echo "$n job(s) réussi(s) lancé(s) par operateur"
else echo "aucun job réussi lancé par l'utilisateur operateur : connectez-vous avec lui et lancez le template"; exit 1; fi
```

## 4. Planifier et auditer

**Un planning.** Dans le template, onglet **Schedules**, **Add** : nom `chaque minute`, fréquence
**Minute**, toutes les **1** minute. Enregistrez, et attendez une ou deux minutes : un job part
seul, visible dans **Views > Jobs** avec le type de lancement *Scheduled*. Le survey n'est pas
posé : un planning utilise les réponses par défaut, ou celles saisies dans le planning lui-même.

**L'audit.** Ouvrez **Views > Activity Stream** : chaque création, modification et lancement y est
daté, avec son auteur, `admin` ou `operateur`. C'est le besoin « traçabilité » du premier chapitre,
et la réponse à la question « qui a lancé quoi, quand ? ».

Supprimez ensuite le planning (icône de corbeille dans l'onglet **Schedules**), pour qu'il ne relance
pas le job toutes les minutes.

```verify
out=$(curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/jobs/?launch_type=scheduled") \
  || { echo "AWX ne répond pas"; exit 1; }
n=$(echo "$out" | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["count"])')
if [ "$n" -ge 1 ]; then echo "$n job(s) lancé(s) par un planning"
else echo "aucun job planifié pour l'instant : créez le planning, et attendez la minute suivante"; exit 1; fi
```

## Nettoyer

Supprimez les deux cibles, puis arrêtez AWX et supprimez ses volumes : base, projets, images d'EE
téléchargées par podman. L'image `layers-awx-receptor:24.6.1` est retirée aussi ; les images
téléchargées par Docker (`awx`, `awx-ee`, `postgres`, `redis`) restent sur votre poste.

```exec
label: Supprimer les cibles et arrêter AWX
---
docker rm -f layers-cible1 layers-cible2 || true
docker compose -f atelier/awx/compose.yml -p layers-awx down -v
docker image rm layers-awx-receptor:24.6.1 || true
```

```verify
if docker ps -a --format '{{.Names}}' | grep -qE '^(layers-awx-|layers-cible[12]$)'; then
  echo "des conteneurs AWX ou des cibles existent encore : lancez le bloc ci-dessus"; exit 1
fi
if docker volume ls -q | grep -q '^layers-awx_'; then
  echo "des volumes layers-awx_* existent encore : l'arrêt doit se faire avec down -v"; exit 1
fi
echo "AWX arrêté, cibles et volumes supprimés"
```
