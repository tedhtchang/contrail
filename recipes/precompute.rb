node.set['openstack']['endpoints']['compute-vnc-bind']['host']=node["ipaddress"]
node.set['openstack']['endpoints']['compute-vnc-proxy-bind']['host']=node["ipaddress"]
  
service "ntpd" do
    action [:enable, :start]
end