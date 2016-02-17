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
# Recipe:: yumrepo
#

include_recipe 'yum'

#retrive Contrail yum repo URL
base_contrail_url = node['contrail']['yum_repo_url']
ctlr_contrail_url = node['contrail']['yum_ct_controller_repo_url']
    
base_operatingsystem_dependencies_url = node['contrail']['base_operatingsystem_dependencies_url']

yum_repository 'contrail_install' do
        description 'Contrail_install_repo'
        baseurl base_contrail_url
        repositoryid 'contrail_install_repo'
        gpgcheck false
        sslverify false
        priority '5'
        action :create
end

yum_repository 'contrail_controller' do
        description 'Contrail_controller_repo'
        baseurl ctlr_contrail_url
        repositoryid 'contrail_controller_repo'
        gpgcheck false
        sslverify false
        priority '3'
        action :create
end

if node['contrail']['setup_operatingsystem_dependencies_repo'] == true
        yum_repository 'rhel65-base-repo' do
        description 'RHEL6.5 Base Operating System Repository'
        baseurl base_operatingsystem_dependencies_url
        gpgcheck false
        sslverify false
        action :create
        end
end


