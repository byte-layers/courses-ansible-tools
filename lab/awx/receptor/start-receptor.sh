#!/bin/sh
set -e
# 1. cgroup v2 : déléguer les contrôleurs, comme le fait l'image docker:dind,
#    sinon podman ne peut pas créer les cgroups de ses conteneurs
mkdir -p /sys/fs/cgroup/init
xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || :
sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || :

# 2. Au premier démarrage, ce que l'opérateur AWX range dans des secrets Kubernetes :
#    une autorité de certification, le certificat du nœud, la clé de signature des jobs
R=/etc/receptor
if [ ! -f $R/tls/receptor.crt ]; then
  mkdir -p $R/tls/ca
  receptor --cert-init commonname="AWX demo CA" bits=2048 \
    outcert=$R/tls/ca/mesh-CA.crt outkey=$R/tls/ca/mesh-CA.key
  receptor --cert-makereq bits=2048 commonname=awx-task dnsname=awx-task nodeid=awx-task \
    outreq=$R/tls/receptor.req outkey=$R/tls/receptor.key
  receptor --cert-signreq req=$R/tls/receptor.req cacert=$R/tls/ca/mesh-CA.crt cakey=$R/tls/ca/mesh-CA.key \
    outcert=$R/tls/receptor.crt verify=yes
  openssl genrsa -out $R/work_private_key.pem 4096 2>/dev/null
  openssl rsa -in $R/work_private_key.pem -pubout -out $R/work_public_key.pem 2>/dev/null
fi

# 3. Comme l'opérateur : copier la configuration par défaut au premier démarrage.
#    Le conteneur task d'AWX la réécrira ensuite lui-même.
[ -f $R/receptor.conf ] || cp /etc/receptor-default.conf $R/receptor.conf
# Lisibles et modifiables par AWX, qui tourne sous un autre utilisateur (raccourci de lab)
chmod -R a+rwX $R

exec receptor --config $R/receptor.conf
