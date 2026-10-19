# Une « machine » qui se configure toute seule avec ansible-pull :
# Python, git et ansible-core, rien d'autre. Aucun serveur SSH, aucun agent.
FROM python:3.12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir ansible-core==2.19.3 \
 && git config --system --add safe.directory '*'
# safe.directory : sous Linux, le dépôt monté appartient à votre utilisateur et non à root ;
# sans cette ligne, git refuse de le cloner (« detected dubious ownership »).
