#!/bin/bash

PACK_WORKSPACE=`echo $(cd "$(dirname "$0")"; pwd)`

# upload Contrail roles into Chef
cd $PACK_WORKSPACE/roles
knife role from file *.*

# upload cookbooks
cd $PACK_WORKSPACE
knife cookbook upload contrail -o ../

# copy sample config files
mkdir -p /installer/contrail
cd $PACK_WORKSPACE/files
cp *.* /installer/contrail

# copy node types file
#cd $PACK_WORKSPACE/icmconfiguration
#yes | cp node_types.yml /opt/ibm/cmwo/cli/config/node_types.yml

# prepare contrail yum repo
cd $PACK_WORKSPACE
cp contrail_icm.tar /opt/ibm/cmwo/yum-repo
cd /opt/ibm/cmwo/yum-repo
tar xvf contrail_icm.tar
rm -rf contrail_icm.tar

# copy and apply fixes
cd $PACK_WORKSPACE/files
yes | cp network.rb /opt/ibm/cmwo/chef-repo/cookbooks/openstack-common/libraries/network.rb
#yes | cp ha-controller-basic-node.rb /opt/ibm/cmwo/chef-repo/cookbooks/ibm-openstack-roles/recipes/ha-controller-basic-node.rb
#yes | cp ha-controller-node-without-ml2-plugin.rb /opt/ibm/cmwo/chef-repo/cookbooks/ibm-openstack-roles/recipes/ha-controller-node-without-ml2-plugin.rb
#yes | cp pacemaker-openstack-controller.rb /opt/ibm/cmwo/chef-repo/cookbooks/ibm-openstack-ha/recipes/pacemaker-openstack-controller.rb
#yes | cp rewind-service-actions.rb /opt/ibm/cmwo/chef-repo/cookbooks/ibm-openstack-ha/recipes/rewind-service-actions.rb
#yes | cp os_manage_constants.rb /root/.chef/plugins/knife/os_manage_constants.rb
#yes | cp os_manage_ha_topology.rb /root/.chef/plugins/knife/os_manage_ha_topology.rb
#yes | cp os_manage_topology.rb /root/.chef/plugins/knife/os_manage_topology.rb
cd /opt/ibm/cmwo/chef-repo/cookbooks/
knife cookbook upload openstack-common -o ./
#knife cookbook upload ibm-openstack-roles -o ./
#knife cookbook upload ibm-openstack-ha -o ./
