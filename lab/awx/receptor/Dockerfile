# Le receptor d'AWX, équipé de podman. Hors Kubernetes, AWX lance chaque job dans un conteneur
# d'execution environment, avec podman : ce conteneur joue le rôle d'un nœud d'exécution.
FROM quay.io/ansible/awx-ee:24.6.1
USER root
RUN dnf install -y podman fuse-overlayfs && dnf clean all \
 && git config --system --add safe.directory '*'
# safe.directory : le cache des projets est écrit par AWX (uid 1000) et lu ici par root
COPY containers.conf /etc/containers/containers.conf
COPY start-receptor.sh /usr/local/bin/start-receptor.sh
RUN chmod 0755 /usr/local/bin/start-receptor.sh
ENTRYPOINT ["/usr/local/bin/start-receptor.sh"]
