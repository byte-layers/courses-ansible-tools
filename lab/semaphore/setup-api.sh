#!/usr/bin/env bash
# Recrée par l'API REST de Semaphore tout ce que le chapitre 4 construit dans l'interface :
# projet, dépôt, inventaire, template, planning, puis un premier lancement.
# Il montre que les objets d'un contrôleur se pilotent eux aussi « as code ».
#
# Usage, depuis la racine du dépôt du cours, Semaphore démarré :
#   bash lab/semaphore/setup-api.sh
# Validé avec semaphoreui/semaphore v2.19.16.
set -euo pipefail

BASE=${BASE:-http://127.0.0.1:28030}
LOGIN=${SEM_USER:-admin}
# Le mot de passe vient de atelier/semaphore/.env s'il existe, comme pour compose.yml.
ENV_PASS=$(grep '^ADMIN_PASSWORD=' atelier/semaphore/.env 2>/dev/null | cut -d= -f2- || true)
PASS=${SEM_PASS:-${ENV_PASS:-changeme}}
COOKIE=$(mktemp)
trap 'rm -f "$COOKIE"' EXIT

say() { printf '\n==> %s\n' "$1"; }
api() { curl -sf -b "$COOKIE" -H 'Content-Type: application/json' "$@"; }
id_of() { python3 -I -c 'import sys, json; print(json.load(sys.stdin)["id"])'; }

say "Connexion à $BASE"
curl -sf -c "$COOKIE" -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"auth\":\"$LOGIN\",\"password\":\"$PASS\"}" -o /dev/null \
  || { echo "    connexion refusée : Semaphore tourne-t-il, et le mot de passe est-il celui de atelier/semaphore/.env ?"; exit 1; }
echo "    connecté en tant que $LOGIN"

say "Projet"
PID=$(api -X POST "$BASE/api/projects" -d '{"name":"Atelier (API)","alert":false}' | id_of)
P="$BASE/api/project/$PID"
echo "    projet id=$PID"

# La création d'un projet crée aussi une clé « None » : on la retrouve plutôt que d'en créer une.
KID=$(api "$P/keys" | python3 -I -c 'import sys, json; print([k["id"] for k in json.load(sys.stdin) if k["type"] == "none"][0])')
echo "    clé « None » id=$KID"

say "Dépôt : où est le code"
RID=$(api -X POST "$P/repositories" \
  -d "{\"name\":\"demo-repo\",\"project_id\":$PID,\"git_url\":\"/repos/demo-repo\",\"git_branch\":\"main\",\"ssh_key_id\":$KID}" | id_of)
echo "    dépôt id=$RID (/repos/demo-repo)"

say "Inventaire : sur quoi jouer"
IID=$(api -X POST "$P/inventory" \
  -d "{\"name\":\"local\",\"project_id\":$PID,\"type\":\"static\",\"inventory\":\"[local]\\nlocalhost ansible_connection=local\\n\",\"ssh_key_id\":$KID}" | id_of)
echo "    inventaire id=$IID"

say "Template : quoi jouer"
TID=$(api -X POST "$P/templates" \
  -d "{\"project_id\":$PID,\"name\":\"Réconcilier\",\"playbook\":\"site.yml\",\"inventory_id\":$IID,\"repository_id\":$RID,\"app\":\"ansible\",\"type\":\"\"}" | id_of)
echo "    template id=$TID (site.yml)"

say "Planning : quand jouer"
# Sans repository_id : un cron « aveugle », qui rejoue à chaque échéance et corrige donc les dérives.
# Avec "repository_id": RID, le planning ne lance la tâche que sur un nouveau commit
# (c'est la case « Auto-run task if new git commit have been found » du template).
api -X POST "$P/schedules" \
  -d "{\"project_id\":$PID,\"template_id\":$TID,\"cron_format\":\"* * * * *\",\"active\":true,\"name\":\"chaque minute\"}" >/dev/null
echo "    planning : chaque minute"

say "Premier lancement"
RUN=$(api -X POST "$P/tasks" -d "{\"template_id\":$TID,\"project_id\":$PID}" | id_of)
STATUS=waiting
for _ in $(seq 1 30); do
  STATUS=$(api "$P/tasks/$RUN" | python3 -I -c 'import sys, json; print(json.load(sys.stdin)["status"])')
  case "$STATUS" in success|error|stopped) break ;; esac
  sleep 2
done
echo "    tâche id=$RUN : $STATUS"
