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
# Recipe:: postnetwork
#
#

class ::Chef::Recipe
  include ::Contrail
end

region_name = node['openstack']['region']
openstack_release = node['contrail']['openstack_release']
multi_tenancy = node['contrail']['multi_tenancy']
admin_databag = node['openstack']['secret']['user_passwords_data_bag']
token_databag = node['openstack']['secret']['secrets_data_bag']
admin_name = node['openstack']['identity']['admin_user']
admin_name = "admin" if admin_name.nil? || admin_name.empty?
admin_tenant = node['openstack']['identity']['admin_tenant_name']
admin_tenant = "admin" if admin_tenant.nil? || admin_tenant.empty?

admins = data_bag("#{admin_databag}")
admin_password_item = data_bag_item("#{admin_databag}",'admin',IO.read('/etc/chef/encrypted_data_bag_secret').strip())
simple_token_item = data_bag_item("#{token_databag}",'openstack_simple_token',IO.read('/etc/chef/encrypted_data_bag_secret').strip())
admin_password = admin_password_item['admin']
simple_token = simple_token_item['openstack_simple_token']

admin_password = get_admin_password
simple_token= get_simple_token
region_name=node['contrail']['region_name']
  
search_line='xxxyyyzzz'
insert_line1=" region name=#{region_name}"
insert_line2=" openstack release=#{openstack_release}"
insert_line3=" multi tenancy=#{multi_tenancy}"
insert_line4=" admin password=#{admin_password}"
insert_line5=" simple token=#{simple_token}"
insert_line6=" admin name=#{admin_name}"
insert_line7=" admin tenant=#{admin_tenant}"

bash "create-params" do
    user "root"
    code <<-EOH
        > /tmp/params.txt
    EOH
end

ruby_block "print_params" do
    block do
                file = Chef::Util::FileEdit.new('/tmp/params.txt')
                file.insert_line_if_no_match(/#{search_line}/, insert_line1)
                file.insert_line_if_no_match(/#{search_line}/, insert_line2)
                file.insert_line_if_no_match(/#{search_line}/, insert_line3)
                file.insert_line_if_no_match(/#{search_line}/, insert_line4)
                file.insert_line_if_no_match(/#{search_line}/, insert_line5)
                file.insert_line_if_no_match(/#{search_line}/, insert_line6)
                file.insert_line_if_no_match(/#{search_line}/, insert_line7)
                file.write_file
        end
end
 
