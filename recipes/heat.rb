#
# Cookbook Name:: contrail
# Recipe:: contrail-heat
#
# Copyright 2014, Juniper Networks
#

class ::Chef::Recipe
  include ::Contrail
end

include_recipe "contrail::common"

%w{contrail-openstack}.each do |pkg|
    package pkg do
        action :upgrade
    end
end

%w{ heat-api
    heat-engine
}.each do |svc|
    service svc do
        action [:enable, :start]
    end
end

openstack_controller_node_ip = get_openstack_controller_node_ip
service_token = get_simple_token
admin_token = get_simple_token

bash "heat-server-setup" do
    user  "root"
    code <<-EOC
        echo "SERVICE_TOKEN=#{service_token}" > /etc/contrail/ctrl-details
        echo "SERVICE_TENANT=service" >> /etc/contrail/ctrl-details
        echo "AUTH_PROTOCOL=#{node['contrail']['protocol']['keystone']}" >> /etc/contrail/ctrl-details
        echo "QUANTUM_PROTOCOL=http" >> /etc/contrail/ctrl-details
        echo "ADMIN_TOKEN=#{admin_token}" >> /etc/contrail/ctrl-details
        echo "CONTROLLER=#{openstack_controller_node_ip}" >> /etc/contrail/ctrl-details
        echo "AMQP_SERVER=#{openstack_controller_node_ip}" >> /etc/contrail/ctrl-details
        echo "QUANTUM=#{node['ipaddress']}" >> /etc/contrail/ctrl-details
        echo "QUANTUM_PORT=9696" >> /etc/contrail/ctrl-details
        echo "OPENSTACK_INDEX=1" >> /etc/contrail/ctrl-details
        echo "COMPUTE=#{node['contrail']['compute']['ip']}" >> /etc/contrail/ctrl-details
        echo "CONTROLLER_MGMT=#{node['ipaddress']}" >> /etc/contrail/ctrl-details
        /usr/bin/heat-server-setup.sh
    EOC
end
