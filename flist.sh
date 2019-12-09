#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y build-essential binutils-doc autoconf flex bison libjpeg-dev
apt-get install -y libfreetype6-dev zlib1g-dev libzmq3-dev libgdbm-dev libncurses5-dev
apt-get install -y automake libtool curl git tmux gettext
apt-get install -y nginx
apt-get install -y rabbitmq-server redis-server
apt-get install -y postgresql
apt-get install -y python3 python3-pip python3-dev virtualenvwrapper
apt-get install -y libxml2-dev libxslt-dev
apt-get install -y libssl-dev libffi-dev
apt-get install -y sudo openssh-server virtualenv
adduser taiga
adduser taiga sudo
passwd -d taiga

cd /home/taiga
git clone https://github.com/threefoldtech/Threefold-Circles.git taiga-back
cd taiga-back
git checkout production

su taiga && cd /home/taiga && sudo virtualenv -p /usr/bin/python3 taiga

local_file='/home/taiga/taiga-back/settings/local.py'
/bin/cat <<EOF > $local_file
from .common import *
import os

MEDIA_URL = "http://localhost/media/"
STATIC_URL = "http://localhost/static/"
SITES["front"]["scheme"] = "http"
SITES["front"]["domain"] = "localhost"

SECRET_KEY = os.getenv("SECRET_KEY")

DEBUG = False
PUBLIC_REGISTER_ENABLED = True

DEFAULT_FROM_EMAIL = "no-reply@example.com"
SERVER_EMAIL = DEFAULT_FROM_EMAIL

# CELERY_ENABLED = True

EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
EVENTS_PUSH_BACKEND_OPTIONS = {"url": f"amqp://taiga:{SECRET_KEY}@localhost:5672/taiga"}

# Uncomment and populate with proper connection parameters
# for enable email sending. EMAIL_HOST_USER should end by @domain.tld
# EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
# EMAIL_USE_TLS = False
EMAIL_HOST = os.getenv("EMAIL_HOST")
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
# EMAIL_PORT = 25

# Uncomment and populate with proper connection parameters
# for enable github login/singin.
# GITHUB_API_CLIENT_ID = "yourgithubclientid"
# GITHUB_API_CLIENT_SECRET = "yourgithubclientsecret"
EOF

cd /home/taiga
git clone https://github.com/threefoldtech/Threefold-Circles-front-dist.git taiga-front-dist
cd taiga-front-dist
git checkout production
cp /home/taiga/taiga-front-dist/dist/conf.example.json /home/taiga/taiga-front-dist/dist/conf.json

# Events installation

cd /home/taiga
git clone https://github.com/threefoldtech/Threefold-Circles-events.git taiga-events
su taiga \
&& cd taiga-events \
&& curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - \
&& sudo apt-get install -y nodejs \
&& npm install \
&& cp config.example.json config.json

# configure nginx

rm /etc/nginx/sites-enabled/default
mkdir -p /home/taiga/logs

# below is setup of MySQL master node
nginx_file='/etc/nginx/conf.d/taiga.conf'
/bin/cat <<EOF > $nginx_file

server {
    listen 80 default_server;
    server_name _;

    large_client_header_buffers 4 32k;
    client_max_body_size 50M;
    charset utf-8;

    access_log /home/taiga/logs/nginx.access.log;
    error_log /home/taiga/nginx.error.log;

    # Frontend
    location / {
        root /home/taiga/taiga-front-dist/dist/;
        try_files $uri $uri/ /index.html;
    }

    # Backend
    location /api {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8001/api;
        proxy_redirect off;
    }

    # Admin access (/admin/)
    location /admin {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8001$request_uri;
        proxy_redirect off;
    }

    # Static files
    location /static {
        alias /home/taiga/taiga-back/static;
    }

    # Media files
    location /media {
        alias /home/taiga/taiga/taiga-back/media;
    }

    # Events
    location /events {
        proxy_pass http://127.0.0.1:8888/events;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
EOF

nginx -t

mkdir -p /opt/bin
prepare_taiga_file='/opt/bin/prepare_taiga.sh'
/bin/cat <<EOF > $prepare_taiga_file

# Install dependencies and populate database
cd /home/taiga/taiga-back
/home/taiga/taiga-back/taiga/bin/pip3 install -r requirements.txt
/home/taiga/taiga-back/taiga/bin/python3 manage.py migrate --noinput
/home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_user
/home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_project_templates
/home/taiga/taiga-back/taiga/bin/python3 manage.py compilemessages
/home/taiga/taiga-back/taiga/bin/python3 manage.py collectstatic --noinput

EOF

tar -cpzf "/root/archives/circles.tar.gz" --exclude dev --exclude sys --exclude proc --exclude /root/archives/ /

