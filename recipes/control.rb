#
# Cookbook Name:: contrail
# Recipe:: contrail-control
#
# Copyright 2014, Juniper Networks
#
cfgm_vip = get_cfgm_virtual_ipaddr

package "contrail-openstack-control" do
    action :upgrade
    notifies :stop, "service[supervisor-control]", :immediately
end

template "/etc/contrail/contrail-control.conf" do
    source "contrail-control.conf.erb"
    mode 00644
    variables(:cfgm_vip   => cfgm_vip)
    notifies :restart, "service[contrail-control]", :delayed
end

template "/etc/contrail/contrail-control-nodemgr.conf" do
    source "contrail-control-nodemgr.conf.erb"
    mode 00644
    variables(:cfgm_vip   => cfgm_vip)
    notifies :restart, "service[contrail-control-nodemgr]", :delayed
end

template "/etc/contrail/contrail-dns.conf" do
    source "contrail-dns.conf.erb"
    mode 00644
    variables(:cfgm_vip   => cfgm_vip)
    notifies :restart, "service[contrail-dns]", :delayed
end

%w{ supervisor-control contrail-control contrail-control-nodemgr contrail-dns }.each do |pkg|
    service pkg do
        action [:enable, :start]
    end
end
