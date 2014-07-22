#!/bin/bash
#
# copyright (c) 2014 enovance sas <licensing@enovance.com>
#
# licensed under the apache license, version 2.0 (the "license"); you may
# not use this file except in compliance with the license. you may obtain
# a copy of the license at
#
# http://www.apache.org/licenses/license-2.0
#
# unless required by applicable law or agreed to in writing, software
# distributed under the license is distributed on an "as is" basis, without
# warranties or conditions of any kind, either express or implied. see the
# license for the specific language governing permissions and limitations
# under the license.

set -e
set -x

source functions.sh

SF_SUFFIX=${SFSUFFIX:-sf.dom}

ROLES="puppetmaster ldap mysql"
ROLES="$ROLES redmine gerrit managesf"
ROLES="$ROLES jenkins commonservices"

BUILD=build
[ -d "$BUILD" ] && rm -Rf $BUILD

generate_keys
generate_hieras
prepare_etc_puppet
wait_all_nodes
# Start a run locally and start the puppet agent service
run_puppet_agent
# Start a run on each node and start the puppet agent service
trigger_puppet_apply
# Set a witness file that tell the bootstraping is done
touch ${BUILD}/bootstrap.done
