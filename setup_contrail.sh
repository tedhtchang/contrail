#!/bin/bash

PACK_WORKSPACE=`echo $(cd "$(dirname "$0")"; pwd)`

# upload Contrail roles into Chef
cd $PACK_WORKSPACE/roles
knife role from file *.*

# upload cookbooks
cd $PACK_WORKSPACE/cookbooks
knife cookbook upload contrail -o ./

# copy sample config files
mkdir -p /installer/contrail
cd $PACK_WORKSPACE/icmconfiguration/full_ha
cp *.* /installer/contrail

# copy node types file
cd $PACK_WORKSPACE/icmconfiguration
yes | cp node_types.yml /opt/ibm/cmwo/cli/config/node_types.yml

# prepare contrail yum repo
cd $PACK_WORKSPACE
cp contrail_icm.tar /opt/ibm/cmwo/yum-repo
cd /opt/ibm/cmwo/yum-repo
tar xvf contrail_icm.tar
rm -rf contrail_icm.tar

# copy and apply network.rb fix
cd $PACK_WORKSPACE/patches
yes | cp network.rb /opt/ibm/cmwo/chef-repo/cookbooks/openstack-common/libraries/network.rb
cd /opt/ibm/cmwo/chef-repo/cookbooks/
knife cookbook upload openstack-common -o ./