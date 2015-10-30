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
# Recipe:: yum-compute-repo.rb
#

include_recipe 'yum'

base_contrail_url = node['contrail']['yum_compute_repo_url']

yum_repository 'contrail_install' do
        description 'Contrail_compute__repo'
        baseurl base_contrail_url
        repositoryid 'Ccontrail_compute_repo'
        gpgcheck false
        sslverify false
        action :create
end

