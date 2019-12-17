#!/usr/bin/env bash
set -x

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
cd /home/taiga/taiga-events \
&& curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - \
&& npm install \
&& cp config.example.json config.json
