# Réglages Django d'AWX, repris de la ConfigMap de l'opérateur AWX 2.19.1 (sans Kubernetes).
import os
import socket

def get_secret():
    if os.path.exists("/etc/tower/SECRET_KEY"):
        return open('/etc/tower/SECRET_KEY', 'rb').read().strip()

ADMINS = ()
STATIC_ROOT = '/var/lib/awx/public/static'
STATIC_URL = '/static/'
PROJECTS_ROOT = '/var/lib/awx/projects'
JOBOUTPUT_ROOT = '/var/lib/awx/job_status'

# Comme sur Kubernetes : les mises à jour de projet s'exécutent directement dans le conteneur
# receptor (bâti sur l'image d'EE). Les jobs, eux, ne tournent pas dans un « container group »
# Kubernetes : AWX les lance donc dans un conteneur d'EE avec podman, d'où podman dans le receptor.
IS_K8S = True

SECRET_KEY = get_secret()
ALLOWED_HOSTS = ['*']
INTERNAL_API_URL = 'http://127.0.0.1:8052'
AWX_PROOT_ENABLED = False
AWX_AUTO_DEPROVISION_INSTANCES = True
CLUSTER_HOST_ID = socket.gethostname()
SYSTEM_UUID = '00000000-0000-0000-0000-000000000000'
CSRF_COOKIE_SECURE = False
SESSION_COOKIE_SECURE = False
USE_X_FORWARDED_PORT = True
BROADCAST_WEBSOCKET_PORT = 8052
BROADCAST_WEBSOCKET_PROTOCOL = 'http'
RECEPTOR_LOG_LEVEL = 'info'
