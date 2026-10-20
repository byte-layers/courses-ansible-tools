# Connexion à la base, et secret partagé des websockets entre conteneurs.
import os

DATABASES = {
    'default': {
        'ATOMIC_REQUESTS': True,
        'ENGINE': 'awx.main.db.profiled_pg',
        'NAME': os.environ.get('DATABASE_NAME', 'awx'),
        'USER': os.environ.get('DATABASE_USER', 'awx'),
        'PASSWORD': os.environ['DATABASE_PASSWORD'],
        'HOST': os.environ.get('DATABASE_HOST', 'postgres'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
        'OPTIONS': {'sslmode': 'prefer'},
    }
}

LISTENER_DATABASES = {'default': {'OPTIONS': {'keepalives': 1, 'keepalives_idle': 5, 'keepalives_interval': 5, 'keepalives_count': 5}}}

BROADCAST_WEBSOCKET_SECRET = os.environ['BROADCAST_WEBSOCKET_SECRET']
