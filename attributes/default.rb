###########################################
#
#  Configuration for this cluster
#
###########################################
require 'uri'

### The block for ICM integration  ###
admin_name = node['openstack']['identity']['admin_user']
admin_name = "admin" if admin_name.nil? || admin_name.empty?
admin_tenant = node['openstack']['identity']['admin_tenant_name']
admin_tenant = "admin" if admin_tenant.nil? || admin_tenant.empty?
default['contrail']['admin_databag'] = node['openstack']['secret']['user_passwords_data_bag']
default['contrail']['token_databag'] = node['openstack']['secret']['secrets_data_bag']
default['contrail']['service_databag'] = node['openstack']['secret']['service_passwords_data_bag']

default['contrail']['setup_operatingsystem_dependencies_repo'] = "false"
uri = URI("#{Chef::Config[:chef_server_url]}")
chef_server_ip = uri.host
default['contrail']['yum_repo_url'] = "https://#{chef_server_ip}:14443/yum-repo/contrail/"
default['contrail']['yum_compute_repo_url'] = "https://#{chef_server_ip}:14443/yum-repo/contrail-compute/"
default['contrail']['yum_os_controller_repo_url'] = "https://#{chef_server_ip}:14443/yum-repo/contrail-os-controller/"
default['contrail']['yum_ct_controller_repo_url'] = "https://#{chef_server_ip}:14443/yum-repo/contrail-ct-controller/"
default['contrail']['keystone_ip'] = "#{node['openstack']['endpoints']['host']}"
default['contrail']['os_controller_ip'] = "#{node['openstack']['endpoints']['host']}" 
default['contrail']['ct_controller_interface'] = node['network']['default_interface'] 
default['contrail']['kernel_version'] = "3.10.0-229.el7.x86_64"
default['contrail']['compute']['server_role'] = "contrail-icm-compute"

### The block for ICM integration  ###
  
default['contrail']['openstack_release'] = "kilo"
default['contrail']['multi_tenancy'] = false
default['contrail']['manage_neutron'] = false
default['contrail']['manage_nova_compute'] = true
default['contrail']['router_asn'] = 64512
default['contrail']['neutron_token'] = "token123"
default['contrail']['service_token'] = "token123"
default['contrail']['admin_token'] = "token123"
default['contrail']['admin_password'] = "password"
default['contrail']['admin_user'] = admin_name
default['contrail']['admin_tenant_name'] = admin_tenant
default['contrail']['region_name'] = node['openstack']['region']
#default['contrail']['yum_repo_url'] = "file:///opt/contrail/contrail_install_repo/"
default['contrail']['provision'] = true
# ha
default['contrail']['ha'] = false
default['contrail']['cfgm']['vip'] =  "#{node['contrail']['network_ip']}"
default['contrail']['cfgm']['pfxlen'] = "#{node['contrail']['network_pfxlen']}"
# Openstack
default['contrail']['openstack_controller_role'] = "contrail-openstack"
default['contrail']['openstack_root_pw'] = "contrail123"
# Keystone
default['contrail']['protocol']['keystone'] = "http"
# Control
default['contrail']['controller_role'] = "contrail-config"
# rabbitmq
default['contrail']['rabbitmq'] = true
# Compute
default['contrail']['compute']['interface'] = "eth1"
default['contrail']['compute']['hostname'] = "a6s35"
default['contrail']['compute']['ip'] = "10.84.13.35"
default['contrail']['compute']['netmask'] = "255.255.255.0"
default['contrail']['compute']['gateway'] = "10.84.13.254"
default['contrail']['compute']['cidr'] = "10.84.13.0/24"
default['contrail']['compute']['dns1'] = "10.84.9.17"
default['contrail']['compute']['dns2'] = "10.84.5.100"
default['contrail']['compute']['dns3'] = "172.24.16.115"
default['contrail']['compute']['domain'] = "contrail.juniper.net"
