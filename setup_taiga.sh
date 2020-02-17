#!/usr/bin/env bash
set -ex

# create a database user and taiga database
#sudo -u postgres createuser taiga
su - postgres -c "psql -t -c '\du' | cut -d \| -f 1 | grep -qw taiga && echo taiga user already exist || createuser taiga"
su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw  taiga && echo taiga database is already exist || createdb taiga -O taiga --encoding='utf-8' --locale=en_US.utf8 --template=template0"

if getent passwd taiga; then
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
 #   cd /home/taiga/taiga-back
 #   virtualenv -p /usr/bin/python3 taiga
 #   /home/taiga/taiga-back/taiga/bin/pip3 install -r requirements.txt
else
    echo taiga back dir is already exist, updating taiga-back repo now
    cd /home/taiga/taiga-back
    git stash
    git pull

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
    echo taiga_front-dist is already exist, updating taiga-front repo now
    cd /home/taiga/taiga-front-dist
    git stash
    git pull


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
    echo taiga-events is already exist, updating taiga-event repo
    cd /home/taiga/taiga-events
    git stash
    git pull
fi
# complete events installation
su taiga \
&& cd /home/taiga/taiga-events \
&& npm install \
&& cp config.example.json config.json
