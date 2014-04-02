#!/bin/bash

set -x
set -e

. ../function.sh

ROLES="sf-puppetmaster sf-ldap sf-mysql sf-redmine sf-jenkins sf-gerrit"
EDEPLOY_LXC=/srv/edeploy-lxc/edeploy-lxc

if [ -z "$1" ] || [ "$1" == "start" ]; then
    new_build
    cp sf-lxc.yaml ${BUILD}/sf-host.yaml
    # Fix jenkins for lxc
    sudo sed -i 's/^#*JAVA_ARGS.*/JAVA_ARGS="-Djava.awt.headless=true -Xmx256m"/g' /var/lib/debootstrap/install/D7-H.1.0.0/softwarefactory/etc/default/jenkins
    # Update puppet modules
    sudo mkdir -p /var/lib/debootstrap/install/D7-H.1.0.0/install-server/etc/puppet/{modules,manifests}
    sudo cp ../puppet/hiera.yaml /var/lib/debootstrap/install/D7-H.1.0.0/install-server/etc/puppet/
    sudo rsync -a ../puppet/modules/ /var/lib/debootstrap/install/D7-H.1.0.0/install-server/etc/puppet/modules/
    sudo rsync -a ../puppet/manifests/ /var/lib/debootstrap/install/D7-H.1.0.0/install-server/etc/puppet/manifests/
    # We alreay have puppetmaster IP, so we can generate cloudinit
    generate_cloudinit
    sudo ${EDEPLOY_LXC} --config sf-lxc.yaml restart || exit -1
    sf_postconfigure
elif [ "$1" == "stop" ]; then
    sudo ${EDEPLOY_LXC} --config sf-lxc.yaml stop
elif [ "$1" == "clean" ]; then
    sudo ${EDEPLOY_LXC} --config sf-lxc.yaml stop
    rm -Rf ${BUILD}
else
    echo "usage: $0 [start|stop|clean]"
fi