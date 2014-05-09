#!/bin/bash
#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

set -x
set -e

DVER=D7
PVER=H
REL=1.0.0
VERS=${DVER}-${PVER}.${REL}

SF_PREFIX=${SF_PREFIX:-sf}
EDEPLOY_ROLES=${EDEPLOY_ROLES:-/var/lib/debootstrap}
SSH_PUBKEY=/home/ubuntu/.ssh/id_rsa.pub
export SF_PREFIX

ROLES="${SF_PREFIX}-puppetmaster ${SF_PREFIX}-ldap ${SF_PREFIX}-mysql ${SF_PREFIX}-redmine"
ROLES="$ROLES ${SF_PREFIX}-gerrit ${SF_PREFIX}-managesf ${SF_PREFIX}-jenkins ${SF_PREFIX}-commonservices"

EDEPLOY_LXC=/srv/edeploy-lxc/edeploy-lxc
CONFTEMPDIR=/tmp/lxc-conf
# Need to be select randomly
SSHPASS=heat

function get_ip {
    grep -B 1 "\-$1" sf-lxc.yaml | head -1 | awk '{ print $2 }'
}

if [ -z "$1" ] || [ "$1" == "start" ]; then
    [ ! -d ${CONFTEMPDIR} ] && mkdir -p ${CONFTEMPDIR}
    cp sf-lxc.yaml $CONFTEMPDIR
    cp ../cloudinit/* $CONFTEMPDIR
    # Complete the sf-lxc template used by edeploy-lxc tool
    sed -i "s/SF_PREFIX/${SF_PREFIX}/g" ${CONFTEMPDIR}/sf-lxc.yaml
    sed -i "s/VERS/${VERS}/g" ${CONFTEMPDIR}/sf-lxc.yaml
    sed -i "s#CIPATH#${CONFTEMPDIR}#g" ${CONFTEMPDIR}/sf-lxc.yaml
    sed -i "s#SSH_PUBKEY#${SSH_PUBKEY}#g" ${CONFTEMPDIR}/sf-lxc.yaml
    sed -i "s#EDEPLOY_ROLES#${EDEPLOY_ROLES}#g" ${CONFTEMPDIR}/sf-lxc.yaml
    # Complete all the cloudinit templates
    sed -i "s/SF_PREFIX/${SF_PREFIX}/g" ${CONFTEMPDIR}/*.cloudinit
    sed -i "s/SSHPASS/${SSHPASS}/g" ${CONFTEMPDIR}/*.cloudinit
    for r in ldap mysql redmine gerrit managesf jenkins commonservices; do
        ip=`get_ip $r`
        sed -i "s/${r}_host/$ip/g" ${CONFTEMPDIR}/puppetmaster.cloudinit
    done
    ip=`get_ip puppetmaster`
    sed -i "s/MY_PRIV_IP=.*/MY_PRIV_IP=$ip/" ${CONFTEMPDIR}/puppetmaster.cloudinit
    # Fix jenkins for lxc
    sudo sed -i 's/^#*JAVA_ARGS.*/JAVA_ARGS="-Djava.awt.headless=true -Xmx256m"/g' \
        ${EDEPLOY_ROLES}/install/${DVER}-${PVER}.${REL}/softwarefactory/etc/default/jenkins
    sudo ${EDEPLOY_LXC} --config ${CONFTEMPDIR}/sf-lxc.yaml restart || exit -1
elif [ "$1" == "stop" ]; then
    [ -f "${CONFTEMPDIR}/sf-lxc.yaml" ] && sudo ${EDEPLOY_LXC} --config ${CONFTEMPDIR}/sf-lxc.yaml stop
elif [ "$1" == "clean" ]; then
    [ -f "${CONFTEMPDIR}/sf-lxc.yaml" ] && sudo ${EDEPLOY_LXC} --config ${CONFTEMPDIR}/sf-lxc.yaml stop || echo
    rm -Rf ${CONFTEMPDIR} || echo
    # make sure all lxc are shutdown
    #for instance in $(sudo lxc-ls --active); do
    for instance in $(sudo lxc-ls); do
        #sudo lxc-stop --kill --name ${instance} || echo
        sudo lxc-stop --name ${instance} || echo
    done
else
    echo "usage: $0 [start|stop|clean]"
fi
