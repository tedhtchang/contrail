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

bash "post-restart-cassandra" do
    user "root"
    code <<-EOH
        service contrail-database restart
        service supervisor-database restart
        service supervisor-config restart
        service supervisor-control restart
    EOH
end