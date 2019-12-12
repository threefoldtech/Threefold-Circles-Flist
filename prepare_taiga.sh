#!/usr/bin/env bash
set -x

echo "checking env variables was set correctly "

if [[ -z "$SECRET_KEY" ]] || [[ -z "$EMAIL_HOST" ]] || [[ -z "$EMAIL_HOST_USER" ]] || [[ -z "$EMAIL_HOST_PASSWORD" ]] || [[ -z "$HOST_IP" ]] || [[ -z "$HTTP_PORT" ]] ; then
    echo " one of below variables are not set yet, Please set it in creating your container"
    echo "SECRET_KEY EMAIL_HOST EMAIL_HOST_USER EMAIL_HOST_PASSWORD HOST_IP HTTP_PORT"
    exit 1
fi

# edit backend
sed -i "s|http://localhost/static/|https://$HOST_IP/static/|g"  /home/taiga/taiga-back/settings/local.py
sed -i "s|http://localhost/media/|https://$HOST_IP/media/|g" /home/taiga/taiga-back/settings/local.py
sed -i "s|'localhost'|\"$HOST_IP\"|g" /home/taiga/taiga-back/settings/local.py
sed -i "s|'http'|'https'|g" /home/taiga/taiga-back/settings/local.py

# Edit conf files for frontend
sed -i "s|circles.threefold.me|$HOST_IP|g" /home/taiga/taiga-front-dist/dist/conf.json

sed -i "s/listen 80 default_server/listen $HTTP_PORT default_server/g" /etc/nginx/conf.d/taiga.conf


# Edit config.json for events
sed -i "s/guest:guest/taiga:$SECRET_KEY/g" /home/taiga/taiga-events/config.json
sed -i "s/mysecret/$SECRET_KEY/g" /home/taiga/taiga-events/config.json

# Install dependencies and populate database
cd /home/taiga/taiga-back
virtualenv -p /usr/bin/python3 taiga
/home/taiga/taiga-back/taiga/bin/pip3 install -r requirements.txt
/home/taiga/taiga-back/taiga/bin/python3 manage.py migrate --noinput
/home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_user
/home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_project_templates
/home/taiga/taiga-back/taiga/bin/python3 manage.py compilemessages
/home/taiga/taiga-back/taiga/bin/python3 manage.py collectstatic --noinput

