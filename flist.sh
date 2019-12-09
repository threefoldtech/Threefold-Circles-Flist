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

# configure nginx and startup toml

rm /etc/nginx/sites-enabled/default
mkdir -p /home/taiga/logs
nginx_file='/etc/nginx/conf.d/taiga.conf'
wget https://raw.githubusercontent.com/threefoldtech/Threefold-Circles-Flist/master/nginx_conf -O $nginx_file
wget https://raw.githubusercontent.com/threefoldtech/Threefold-Circles-Flist/master/startup.toml -O /.startup.toml

sudo nginx -t
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

