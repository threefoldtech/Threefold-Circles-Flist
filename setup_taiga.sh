#!/usr/bin/env bash
set -ex

if getent passwd taiga2; then
    echo username taiga is already exist
else
    adduser taiga
    adduser taiga sudo
    passwd -d taiga
fi

if [[ ! -d /home/taiga/taiga-back ]] ; then
    cd /home/taiga
    git clone https://github.com/threefoldtech/Threefold-Circles.git taiga-back
    cd taiga-back
    git checkout production
    su taiga && cd /home/taiga && sudo virtualenv -p /usr/bin/python3 taiga
    local_file='/home/taiga/taiga-back/settings/local.py'
    wget https://raw.githubusercontent.com/threefoldtech/Threefold-Circles-Flist/master/local.py -O $local_file
    # Install dependencies and populate database
    cd /home/taiga/taiga-back
    virtualenv -p /usr/bin/python3 taiga
    /home/taiga/taiga-back/taiga/bin/pip3 install -r requirements.txt
    /home/taiga/taiga-back/taiga/bin/python3 manage.py migrate --noinput
    /home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_user
    /home/taiga/taiga-back/taiga/bin/python3 manage.py loaddata initial_project_templates
    /home/taiga/taiga-back/taiga/bin/python3 manage.py compilemessages
    /home/taiga/taiga-back/taiga/bin/python3 manage.py collectstatic --noinput
else
    echo taiga back dir is already exist

fi

if [[ ! -d /home/taiga/taiga-front-dist ]] ; then
    cd /home/taiga
    git clone https://github.com/threefoldtech/Threefold-Circles-front-dist.git taiga-front-dist
    cd taiga-front-dist
    git checkout production
    git pull

    taiga_front_conf='/home/taiga/taiga-front-dist/dist/conf.json'
    wget https://raw.githubusercontent.com/threefoldtech/Threefold-Circles-Flist/master/taiga-front-dist.conf -O $taiga_front_conf

else
    echo taiga_front-dist is already exist

fi
# Events installation

if [[ ! -d /home/taiga/taiga-events ]]; then
    cd /home/taiga
    git clone https://github.com/threefoldtech/Threefold-Circles-events.git taiga-events
    su taiga \
    && cd taiga-events \
    && git checkout master \
    && git pull

else
    echo taiga-events is already exist
fi
# complete events installation
su taiga \
&& cd /home/taiga/taiga-events \
&& npm install \
&& cp config.example.json config.json
