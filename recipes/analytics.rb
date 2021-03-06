
#
# Cookbook Name:: contrail
# Recipe:: contrail-analytics
#
# Copyright 2014, Juniper Networks
#

class ::Chef::Recipe
  include ::Contrail
end

package "contrail-openstack-analytics" do
    action :upgrade
    notifies :stop, "service[supervisor-analytics]", :immediately
end

database_nodes = get_database_nodes
cfgm_vip = get_cfgm_virtual_ipaddr

%w{ analytics-api
    analytics-nodemgr
    collector
    query-engine
}.each do |pkg|
    template "/etc/contrail/contrail-#{pkg}.conf" do
        source "contrail-#{pkg}.conf.erb"
        owner "contrail"
        group "contrail"
        mode 00640
        variables(:servers    => database_nodes,
                  :cfgm_vip   => cfgm_vip)
        notifies :restart, "service[contrail-#{pkg}]", :immediately
    end
end

template "/etc/contrail/contrail-alarm-gen.conf" do
   source "contrail-alarm-gen.conf.erb"
   owner "contrail"
   group "contrail"
   mode 00640
   variables(:servers    => database_nodes,
             :cfgm_vip   => cfgm_vip)
   action :create
end

template "/etc/contrail/contrail-snmp-collector.conf" do
   source "contrail-snmp-collector.conf.erb"
   owner "contrail"
   group "contrail"
   mode 00640
   variables(:servers    => database_nodes,
             :cfgm_vip   => cfgm_vip)
   action :create
end

%w{ supervisor-analytics
    contrail-analytics-api
    contrail-analytics-nodemgr
    contrail-collector
    contrail-query-engine
    contrail-snmp-collector
}.each do |pkg|
    service pkg do
        action [:enable, :start]
    end
end

bash "restart_analytics" do
    user "root"
    code <<-EOH
        service supervisor-analytics restart
    EOH
end
