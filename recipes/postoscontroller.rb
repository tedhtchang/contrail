# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#
# Cookbook Name:: contrail
# Recipe:: postregion
#

class ::Chef::Recipe
  include ::Contrail
end

admin_password = get_admin_password

template "/tmp/heat_to_append.erb" do
   source "heat_to_append.erb"
   variables(:admin_password => admin_password)
   action :create
end
 


#yum install -y python-contrail python-bottle python-gevent contrail-heat
%w{python-bottle python-gevent python-contrail contrail-heat}.each do |pkg|
	package pkg do
		action :install
	end
end

bash "update-heat" do
    user "root"
    code <<-EOH
        sed -i 's|#plugin_dirs=/usr/lib64/heat,/usr/lib/heat|plugin_dirs=/usr/lib/heat/resources|' /etc/heat/heat.conf
        cat /tmp/heat_to_append.erb >> /etc/heat/heat.conf
        rm /tmp/heat_to_append.erb
    EOH
    not_if "grep -q 'plugin_dirs=/usr/lib/heat/resources' /etc/heat/heat.conf"
end

neutron_password = get_neutron_password

bash "update-neutron" do
    user "root"
    code <<-EOH
        sed -i '/service_plugins = neutron_plugin_contrail.plugins.opencontrail.loadbalancer.plugin.LoadBalancerPlugin/d' /etc/neutron/neutron.conf
        sed -i 's|admin_password =|admin_password = #{neutron_password}|' /etc/neutron/neutron.conf
        sed -i '/admin_token/d' /etc/neutron/neutron.conf
    EOH
    not_if "grep -q 'admin_password = #{neutron_password}' /etc/neutron/neutron.conf"
end

bash "update-neutron-rabbit" do
    user "root"
    code <<-EOH
        sed -i 's|rabbit_hosts|rabbit_host|' /etc/neutron/neutron.conf
    EOH
  not_if { node['contrail']['ha'] == true }
end

bash "restart_neutron" do
    user "root"
    code <<-EOH
        service neutron-server restart
    EOH
end

