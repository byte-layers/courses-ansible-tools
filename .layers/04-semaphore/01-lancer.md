---
title: "Lancer Semaphore"
description: "Le dépôt surveillé, le compose.yml, le premier démarrage"
---

## Le dépôt surveillé

Semaphore exécute des playbooks qu'il **tire d'un dépôt git**, comme ansible-pull. Préparez ce
dépôt dans `atelier/semaphore/demo-repo/`. Le playbook est fourni :
[lab/semaphore/demo-repo/site.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/semaphore/demo-repo/site.yml)
ne contient qu'une tâche, qui écrit un fichier témoin `/tmp/gitops-reconcile.txt` sur la machine
qui l'exécute. Ici, ce sera le conteneur de Semaphore lui-même : de quoi prouver, simplement, que le
contrôleur a tiré le dépôt et rejoué le playbook.

Le bloc ci-dessous copie le playbook, puis en fait un vrai dépôt git avec un premier commit :

```exec
label: Préparer le dépôt surveillé
---
mkdir -p atelier/semaphore/demo-repo
cp lab/semaphore/demo-repo/site.yml atelier/semaphore/demo-repo/site.yml
git -C atelier/semaphore/demo-repo init -q -b main
git -C atelier/semaphore/demo-repo add site.yml
git -C atelier/semaphore/demo-repo -c user.name=atelier -c user.email=atelier@example.com commit -qm "playbook de réconciliation"
git -C atelier/semaphore/demo-repo log --oneline
```

```verify
r=atelier/semaphore/demo-repo
if [ ! -f "$r/site.yml" ]; then echo "absent : $r/site.yml"; exit 1; fi
if ! git -C "$r" rev-parse HEAD >/dev/null 2>&1; then echo "$r n'est pas un dépôt git avec un commit : lancez le bloc ci-dessus"; exit 1; fi
echo "dépôt prêt : $(git -C "$r" log --oneline -1)"
```

## Le compose.yml

Semaphore garde ses projets, ses templates et l'historique de ses tâches dans une base de données.
Il sait utiliser une base embarquée pour un essai rapide ; on choisit ici **PostgreSQL**, comme en
production. Le fichier `compose.yml` décrit donc deux services : PostgreSQL, et Semaphore lui-même. Créez `atelier/semaphore/compose.yml` et complétez les trous :

🚧 **À compléter** — `atelier/semaphore/compose.yml`

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: semaphore
      POSTGRES_PASSWORD: ${DB_PASSWORD:-semaphore_pw}
      POSTGRES_DB: semaphore
    volumes:
      - semaphore_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U semaphore"]
      interval: 5s
      timeout: 3s
      retries: 10

  semaphore:
    image: semaphoreui/semaphore:v2.19.16
    ports:
      - "127.0.0.1:28030:3000"              # l'interface, sur votre poste seulement
    volumes:
      - ./demo-repo:/repos/demo-repo:ro     # le dépôt surveillé, en lecture seule
      - ./gitconfig:/etc/gitconfig:ro       # autorise git à lire ce dépôt
    environment:
      SEMAPHORE_DB_DIALECT: postgres
      SEMAPHORE_DB_HOST:                     # TODO : le nom du service de la base
      SEMAPHORE_DB_PORT: 5432
      SEMAPHORE_DB_USER: semaphore
      SEMAPHORE_DB_PASS: ${DB_PASSWORD:-semaphore_pw}
      SEMAPHORE_DB: semaphore
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ADMIN_PASSWORD: ${ADMIN_PASSWORD:-changeme}
      SEMAPHORE_ADMIN_NAME: Admin
      SEMAPHORE_ADMIN_EMAIL: admin@example.com
    depends_on:
      postgres:
        condition:                           # TODO : attendre que le healthcheck de la base passe

volumes:
  semaphore_db:
```

Voici le rôle de chaque élément important :

| Élément | Rôle |
|---|---|
| `image: …:v2.19.16` | une version **épinglée** : la même pour tout le monde, pas de surprise au prochain téléchargement |
| `127.0.0.1:28030:3000` | l'interface n'écoute que sur votre poste, sans être exposée sur le réseau |
| `./demo-repo:/repos/demo-repo:ro` | le dépôt préparé plus haut, vu dans le conteneur sous `/repos/demo-repo` |
| `./gitconfig:/etc/gitconfig:ro` | une configuration git (`safe.directory`) : sous Linux, le dépôt appartient à votre utilisateur et non à celui du conteneur, et git refuserait sinon de le cloner |
| `SEMAPHORE_DB_HOST` | dans un réseau Compose, un service se joint par **son nom** |
| `healthcheck` + `depends_on: condition` | Semaphore ne démarre qu'une fois la base **prête à répondre**, sinon il plante au démarrage |
| `SEMAPHORE_ADMIN_*` | le compte administrateur, créé au **premier** démarrage |
| `${DB_PASSWORD:-semaphore_pw}` | la valeur vient du fichier `.env` s'il existe, sinon de la valeur par défaut |

> 📖 [Installer Semaphore avec Docker](https://docs.semaphoreui.com/administration-guide/installation/docker/) ·
> [Compose : `depends_on` et `condition`](https://docs.docker.com/reference/compose-file/services/#depends_on)

```verify
f=atelier/semaphore/compose.yml
if [ ! -f "$f" ]; then echo "absent : $f"; exit 1; fi
if ! docker compose -f "$f" config >/dev/null 2>&1; then
  echo "$f n'est pas valide :"; docker compose -f "$f" config 2>&1 | head -3; exit 1
fi
cfg=$(docker compose -f "$f" config --format json 2>/dev/null)
echo "$cfg" | python3 -I -c '
import sys, json
c = json.load(sys.stdin)["services"]
s = c["semaphore"]
errors = []
if not any(v.get("target") == "/etc/gitconfig" for v in s.get("volumes", [])):
    errors.append("le montage ./gitconfig:/etc/gitconfig:ro manque")
if s["environment"].get("SEMAPHORE_DB_HOST") != "postgres":
    errors.append("SEMAPHORE_DB_HOST doit être le nom du service de la base : postgres")
if s.get("depends_on", {}).get("postgres", {}).get("condition") != "service_healthy":
    errors.append("depends_on.postgres.condition doit attendre le healthcheck : service_healthy")
if not any(p.get("host_ip") == "127.0.0.1" and str(p.get("published")) == "28030" for p in s.get("ports", [])):
    errors.append("le port doit être publié sur 127.0.0.1:28030")
print("\n".join(errors) or "compose.yml complet")
sys.exit(1 if errors else 0)
'
```

```hint
Le nom du service de la base est la clé sous `services:` : `postgres`. Pour la condition, la
documentation de Compose liste trois valeurs ; celle qui attend le healthcheck est `service_healthy`.
```

````solution
La solution de référence est dans le dépôt :
[lab/semaphore/compose.yml](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/semaphore/compose.yml).
Les deux trous se complètent ainsi :

- `SEMAPHORE_DB_HOST: postgres`, le nom du service de la base ;
- `condition: service_healthy`, dans le bloc `postgres:` de `depends_on:`.
````

## Démarrer

Deux fichiers fournis complètent le `compose.yml`. Le fichier `.env` fixe les mots de passe ; son
modèle,
[lab/semaphore/.env.example](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/semaphore/.env.example),
contient les deux valeurs du cours, que vous garderez telles quelles. Le fichier
[lab/semaphore/gitconfig](https://github.com/byte-layers/courses-ansible-tools/blob/main/lab/semaphore/gitconfig)
contient les deux lignes `[safe]` et `directory = *` évoquées plus haut. Copiez-les, puis démarrez.
Le premier démarrage télécharge les deux images, PostgreSQL et Semaphore : comptez une minute ou
deux selon votre connexion.

```exec
label: Démarrer Semaphore
---
cp lab/semaphore/.env.example atelier/semaphore/.env
cp lab/semaphore/gitconfig atelier/semaphore/gitconfig
docker compose -f atelier/semaphore/compose.yml -p layers-semaphore up -d
```

L'option `-p layers-semaphore` donne un **nom de projet** Compose, qui préfixe les conteneurs
(`layers-semaphore-semaphore-1`) ; toutes les commandes du chapitre la reprennent. Une fois les
conteneurs lancés, comptez encore 15 à 30 secondes : Semaphore crée son schéma dans la base avant
de répondre.
Interrogez ensuite son point de santé :

```exec
label: Interroger /api/ping
---
curl -s http://127.0.0.1:28030/api/ping; echo
```

La réponse attendue est `pong`. Ouvrez alors **http://127.0.0.1:28030** dans votre navigateur, et
connectez-vous avec `admin` et le mot de passe `changeme`. Ces mots de passe par défaut sont un
raccourci de lab : sur un vrai serveur, on les change dans `.env` **avant** le premier démarrage,
puisque le compte admin est créé à ce moment-là.

```verify
r=$(curl -s --max-time 3 http://127.0.0.1:28030/api/ping || true)
if [ "$r" = "pong" ]; then echo "Semaphore répond : pong"
else echo "pas de réponse de Semaphore sur 127.0.0.1:28030 (réponse : « $r ») : attendez 30 s, ou lisez docker compose -p layers-semaphore logs semaphore"; exit 1; fi
```

```hint
Le port 28030 est peut-être déjà pris : `docker compose … up` l'aurait signalé par
`port is already allocated`. Libérez-le avec `docker ps`, puis relancez.
```
