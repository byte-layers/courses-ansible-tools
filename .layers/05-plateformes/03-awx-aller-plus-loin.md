---
title: "Aller plus loin avec AWX"
description: "Passer de l'utilisation à l'administration d'AWX : les points clés à connaître, puis quatre exercices sur les conteneurs du lab"
---

## Le programme

Lancer un job, vous savez le faire. Cette étape vous fait passer de l'autre côté : celui de
l'**administrateur**, qui décide qui peut lancer quoi, sur quelles machines, quand, et qui garde la
trace de tout. Elle prolonge l'étape précédente sur le **même AWX**, toujours allumé, et dure
environ **1 h 30** : un court résumé de ce qu'un admin sys doit connaître, puis quatre exercices
sur les conteneurs du lab.

| Partie | Durée | Ce que vous faites |
|---|---|---|
| Ce qu'un admin sys doit savoir | 10 min | lire un résumé court, et repérer chaque point dans l'interface |
| 1. Des conteneurs en cible | 40 min | configurer deux conteneurs avec le plugin de connexion Docker, comme dans le cours « premiers pas » |
| 2. Un questionnaire | 15 min | faire saisir une valeur au lancement du job |
| 3. Un opérateur | 15 min | créer un utilisateur qui peut lancer le job, et rien d'autre |
| 4. Planifier et auditer | 10 min | un planning, puis le journal de qui a fait quoi |

Vérifiez d'abord qu'AWX répond toujours. S'il est arrêté, ce bloc le redémarre, avec ses données :

```exec
label: Redémarrer AWX si besoin
---
docker compose -f atelier/awx/compose.yml -p layers-awx up -d
```


```verify
v=$(curl -sf --max-time 3 http://127.0.0.1:28052/api/v2/ping/ 2>/dev/null | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["version"])' 2>/dev/null)
if [ -n "$v" ]; then echo "AWX $v répond sur 127.0.0.1:28052"
else echo "AWX ne répond pas : redémarrez-le avec l'étape précédente (« Démarrer AWX »)"; exit 1; fi
```

## Ce qu'un admin sys doit savoir

Utiliser AWX, c'est cliquer sur « Launch ». L'**administrer**, c'est garantir qu'il tourne, qu'il
est sûr, et qu'on peut le reconstruire. Cinq sujets suffisent pour commencer ; la dernière colonne
dit où les voir dans votre AWX.

| Sujet | Ce qu'il faut savoir | Où le voir |
|---|---|---|
| **Sauvegarde** | la base PostgreSQL **et** la `SECRET_KEY` : sans cette clé, les secrets chiffrés dans la base sont perdus | `atelier/awx/config/SECRET_KEY` |
| **Execution environments** | l'image qui exécute les jobs (chapitre 2) ; en entreprise, on construit les siennes et on les épingle | **Administration > Execution Environments** |
| **Droits** | des rôles par objet : on peut **lancer** un template sans pouvoir le modifier ni lire ses secrets | **Access** ; partie 3 ci-dessous |
| **Audit** | l'Activity Stream trace qui a fait quoi, et quand | **Views > Activity Stream** ; partie 4 |
| **Hygiène** | des tâches de nettoyage purgent les vieux jobs et le journal, sinon la base grossit sans fin | **Administration > Management Jobs** |

D'autres sujets viendront avec l'expérience : la mise à jour par l'opérateur, la capacité et les
groupes d'instances, les coffres de secrets externes, l'envoi des journaux vers un outil central.
Le panorama de début de chapitre les situe.

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

Enregistrez avec **Save**. Ce réglage est puissant, et **global** : tous les jobs de tous les
templates, le Demo compris, accèdent désormais au socket, donc aux droits root sur la machine
Docker. En entreprise, on ne l'accorde qu'en connaissance de cause ; ici, il disparaît au
nettoyage, avec la base d'AWX.

**La collection.** Le plugin de connexion `community.docker.docker_api` vient de la collection
`community.docker`, absente de l'image d'EE. AWX sait l'installer seul, à la synchronisation d'un
projet, s'il trouve un fichier `collections/requirements.yml` dans le dépôt : c'est le cas du dépôt
du cours, à partir du tag `v4`
([collections/requirements.yml](https://github.com/byte-layers/courses-ansible-tools/blob/v4/collections/requirements.yml)).
Ouvrez votre projet `courses-ansible-tools` dans **Resources > Projects**, cliquez sur **Edit**,
remplacez `v1` par **`v4`** dans *Source Control Branch/Tag/Commit*, et enregistrez : le projet se
resynchronise, et installe la collection. Son statut, dans la liste des projets, doit passer à
**Successful** ; si rien ne se passe, cliquez sur l'icône de synchronisation (*Sync*) de sa ligne.

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
organisation `Default`, puis **Save**. Dans son onglet **Groups**, cliquez sur **Add** et créez le
groupe `cibles`, avec ces **Variables** :

```yaml
ansible_connection: community.docker.docker_api
ansible_python_interpreter: /usr/local/bin/python3
```

Les variables d'un groupe s'appliquent à tous ses hôtes : chacun sera joint par l'API Docker, avec le
Python de l'image. Enregistrez, puis, dans l'onglet **Hosts** du groupe, **Add > Add new host** :
créez deux hôtes nommés exactement comme les conteneurs, `layers-cible1` puis `layers-cible2`.

**Le template.** Dans **Resources > Templates**, **Add > Add job template** : nom
`Configurer les cibles`, inventaire `conteneurs`, projet `courses-ansible-tools`, playbook
`lab/awx/playbooks/cibles.yml`. Ce playbook
([lab/awx/playbooks/cibles.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/awx/playbooks/cibles.yml))
dépose dans `/etc/motd-awx` la valeur de la variable `message`, par défaut « Configuré par AWX ».
Laissez le champ **Credentials** vide (aucun mot de passe n'est nécessaire avec la connexion Docker)
et l'**Execution Environment** par défaut. Enregistrez, puis **Launch**.

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
| Default answer | `Configuré par le survey` |

Enregistrez la question, puis activez le survey avec l'interrupteur en haut de l'onglet. Lancez le
template : AWX vous pose la question. Saisissez un message de votre choix, puis relisez les cibles
avec le bloc de la partie précédente.

```verify
for n in 1 2; do
  v=$(docker exec layers-cible$n cat /etc/motd-awx 2>/dev/null)
  if [ "$v" = "Configuré par AWX" ] || [ -z "$v" ]; then
    echo "layers-cible$n contient encore « Configuré par AWX » : activez le survey, relancez le template, et gardez ou changez la réponse proposée"; exit 1
  fi
done
echo "les cibles contiennent votre message : $(docker exec layers-cible1 cat /etc/motd-awx)"
```

## 3. Un opérateur aux droits limités

Créez un utilisateur qui pourra **lancer** ce template, et rien d'autre. Dans **Access > Users**,
**Add** : nom d'utilisateur `operateur`, un mot de passe de votre choix, type **Normal User** (les
deux autres types, *System Auditor* et *System Administrator*, voient ou administrent tout),
organisation `Default`. Enregistrez.

Ouvrez ensuite le template `Configurer les cibles`, onglet **Access**, **Add** : choisissez
**Users**, cochez `operateur`, puis le rôle **Execute**. Enregistrez.

Ouvrez une fenêtre de navigation privée, connectez-vous en `operateur`, et constatez :

| Ce qu'il voit ou fait | Pourquoi |
|---|---|
| il voit le template `Configurer les cibles`, et seulement lui | le rôle Execute ne porte que sur cet objet |
| il peut le lancer, et répondre au survey | c'est exactement ce que donne Execute |
| il voit le nom du projet et de l'inventaire dans le template, mais ne peut pas les ouvrir, ni voir les réglages | aucun rôle ne lui a été donné dessus |
| il ne peut pas modifier le template | il faudrait le rôle Admin sur le template |

Lancez le template en tant qu'`operateur`, avec un message qui le dit, par exemple
« Lancé par l'opérateur ».

```verify
su=$(curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/users/?username=operateur" \
  | python3 -I -c 'import sys, json; r = json.load(sys.stdin)["results"]; print(r[0]["is_superuser"] if r else "absent")')
case "$su" in
  absent) echo "l'utilisateur operateur n'existe pas"; exit 1 ;;
  True) echo "operateur est System Administrator : recréez-le en Normal User"; exit 1 ;;
esac
out=$(curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/jobs/?created_by__username=operateur&status=successful") \
  || { echo "AWX ne répond pas"; exit 1; }
n=$(echo "$out" | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["count"])')
if [ "$n" -ge 1 ]; then echo "$n job(s) réussi(s) lancé(s) par operateur"
else echo "aucun job réussi lancé par l'utilisateur operateur : connectez-vous avec lui et lancez le template"; exit 1; fi
```

## 4. Planifier et auditer

**Un planning.** Dans le template, onglet **Schedules**, **Add** : nom `chaque minute`, ne touchez
pas à *Start date/time* (pré-rempli à maintenant), et choisissez la fréquence **Minute**, toutes les
**1** minute. Personne ne sera là pour répondre au survey quand le planning lancera le job : AWX
exige donc la réponse **dans le planning**. Le formulaire la demande, avec un bouton **Prompt** qui
ouvre l'étape **Survey**, et la réponse par défaut, « Configuré par le survey », y est pré-remplie :
gardez-la, validez, puis enregistrez le planning. Sans réponse, AWX refuse de le créer
(`'message' value missing`).

Attendez une ou deux minutes : un job part seul, visible dans **Views > Jobs** avec le type de
lancement *Scheduled*.

**L'audit.** Ouvrez **Views > Activity Stream** : chaque création, modification et lancement y est
daté, avec son auteur, `admin` ou `operateur`. C'est le besoin « traçabilité » du premier chapitre,
et la réponse à la question « qui a lancé quoi, quand ? ».

Supprimez ensuite le planning (icône de corbeille dans l'onglet **Schedules**), pour qu'il ne relance
pas le job toutes les minutes.

```verify
out=$(curl -sf --max-time 5 -u admin:changeme "http://127.0.0.1:28052/api/v2/jobs/?launch_type=scheduled&status=successful") \
  || { echo "AWX ne répond pas"; exit 1; }
n=$(echo "$out" | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["count"])')
if [ "$n" -ge 1 ]; then echo "$n job(s) lancé(s) par un planning"
else echo "aucun job planifié pour l'instant : créez le planning, et attendez la minute suivante"; exit 1; fi
```

## Nettoyer

Supprimez les deux cibles, puis arrêtez AWX et supprimez ses volumes : base, projets, images d'EE
téléchargées par podman. L'image `layers-awx-receptor:24.6.1` est retirée aussi ; les images
téléchargées par Docker (`awx`, `awx-ee`, `postgres`, `redis`) restent sur votre poste, tout comme le
dossier `atelier/awx/`, avec sa `SECRET_KEY` : il ne sert plus, vous pouvez le supprimer.

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
