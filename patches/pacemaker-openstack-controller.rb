# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#
# Cookbook Name:: ibm-openstack-ha
# Recipe:: pacemaker-openstack-controller
#

# Set node attribute according to the number of HA controllers
controller_node_nums = search_for_nodes_by_role(node['ibm-openstack']['ha']['roles']['ha_controller_node']).size
node.override['openstack']['network']['dhcp']['dhcp_agents_per_network'] = controller_node_nums
node.override['openstack']['network']['l3']['ha']['max_l3_agents_per_router'] = controller_node_nums

openstack_resources = node['ibm-openstack']['ha']['pacemaker']['cluster']['resource']['openstack']
openstack_constraints = node['ibm-openstack']['ha']['pacemaker']['cluster']['constraint']

# Create, enable, and clone all OpenStack controller resources that
# support a basic active/active configuration. Providing clone options
# will enable the resource to be cloned on creation.
resouce_names = %w{memcached identity image-api image-registry
                   network-server network-ovs-agent network-metadata-agent
                   network-l3-agent network-dhcp-agent
                   compute-api compute-metadata-api compute-novncproxy
                   compute-conductor compute-scheduler compute-cert
                   block-storage-api
                   orchestration-api orchestration-api-cfn orchestration-api-cloudwatch
                   orchestration-engine telemetry-api telemetry-collector telemetry-notification httpd}

resouce_names.delete('identity') unless node['ibm-openstack']['first_region']

order_constraint_names = %w{order-memcached-httpd order-memcached-consoleauth
                            order-network-ovs-network-metadata order-network-metadata-network-l3
                            order-network-metadata-network-dhcp}

# Don't create network-l3-agent resource unless l3 is enabled.
unless node['ibm-openstack']['network']['l3']['enable']
  resouce_names.delete('network-l3-agent')
  order_constraint_names.delete('order-network-metadata-network-l3')
end

if node['roles'].include?('ibm-os-ha-controller-node-without-ml2-plugin')
  ml2_agents = %w{network-ovs-agent network-metadata-agent
                    network-l3-agent network-dhcp-agent}
  ml2_agents.each do |deleted_agent|
    resouce_names.delete(deleted_agent)
  end

  order_ml2_agents = %w{order-network-ovs-network-metadata order-network-metadata-network-l3
                          order-network-metadata-network-dhcp}
  order_ml2_agents.each do |deleted_agent|
    order_constraint_names.delete(deleted_agent)
  end
end
# If PRS HA is enabled, then compute-scheduler should not be cloned
if node['ibm-openstack']['prs']['ha']['enabled']
  resouce_names.delete('compute-scheduler')
end

# Create the directory for the httpd OCF resource-agent config files.
directory node['ibm-openstack']['ha']['pacemaker']['cluster']['httpd']['ocf-conf-path'] do
  recursive true
  owner 'root'
  group 'root'
  mode '755'
end

# Create the httpd OCF resource-agent config files.
# These are the files that customize the resource agent monitor.
httpd_ocf_files = [node['ibm-openstack']['ha']['pacemaker']['cluster']['httpd']['ocf-testconf-file'],
                   node['ibm-openstack']['ha']['pacemaker']['cluster']['httpd']['ocf-env-file']]
httpd_ocf_files.each do |file|
  cookbook_file file do
    path "#{node['ibm-openstack']['ha']['pacemaker']['cluster']['httpd']['ocf-conf-path']}/#{file}"
  end
end

resouce_names.each do |resource_element|
  openstack_resource_element = openstack_resources[resource_element]
  pacemaker_resource_element openstack_resource_element['name'] do
    agent openstack_resource_element['agent']
    options openstack_resource_element['options']
    op openstack_resource_element['op']
    meta openstack_resource_element['meta']
    clone_options openstack_resource_element['clone_options']
    clone_on_create openstack_resource_element['clone_on_create']
    wait openstack_resource_element['wait']
    action [:create, :enable, :clone]
  end
end

# Create and enable, but not clone the OpenStack controller resources that
# support an active/passive configuration.
resouce_names_act_pass = %w{block-storage-volume block-storage-scheduler
                            compute-consoleauth telemetry-central
                            telemetry-alarm-evaluator telemetry-alarm-notifier}

# If PRS HA is enabled, then compute-scheduler should be created active/passive
if node['ibm-openstack']['prs']['ha']['enabled']
  resouce_names_act_pass.insert(0, 'compute-scheduler')
end

resouce_names_act_pass.each do |resource_element|
  openstack_resource_element = openstack_resources[resource_element]
  pacemaker_resource_element openstack_resource_element['name'] do
    agent openstack_resource_element['agent']
    options openstack_resource_element['options']
    op openstack_resource_element['op']
    meta openstack_resource_element['meta']
    wait openstack_resource_element['wait']
    action [:create, :enable]
  end
end

# Create the order constraint.
order_constraint_names.each do |constraint|
  openstack_constraint = openstack_constraints[constraint]
  pacemaker_constraint_order openstack_constraint['name'] do
    first_action openstack_constraint['first_action']
    first_resource openstack_constraint['first_resource']
    then_action openstack_constraint['then_action']
    then_resource openstack_constraint['then_resource']
    options openstack_constraint['options']
    action [:add]
  end
end

# Install cwmo_ha_status script
template '/usr/sbin/cmwo_ha_status' do
  source 'cmwo_ha_status.erb'
  owner 'root'
  group 'root'
  mode '0755'
end
