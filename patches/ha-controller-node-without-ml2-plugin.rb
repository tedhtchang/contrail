# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#
# Cookbook Name:: ibm-openstack-roles
# Recipe:: ha-controller-node
#

# Build the full (all-in-one) HA controller node role.
deploy_primary_tag = 'ibm-os-deploy-ha-primary'
deploy_secondary_tag = 'ibm-os-deploy-ha-secondary'
deploy_db_tag = 'ibm-os-deploy-ha-db'

# Determine the tags for this node.
is_deploy_primary = false
is_deploy_secondary = false
is_deploy_db = false
unless node.tags.nil? || node.tags.empty?
  is_deploy_primary = node.tags.include?(deploy_primary_tag)
  is_deploy_secondary = node.tags.include?(deploy_secondary_tag)
  is_deploy_db = node.tags.include?(deploy_db_tag)
end

# Fail if node is not properly tagged.
fail "HA controller node is missing deployment tag. The node must be tagged as "\
  "either a primary (#{deploy_primary_tag}) or a secondary "\
  "(#{deploy_secondary_tag}) node." unless is_deploy_primary || is_deploy_secondary
fail "HA controller node is not tagged correctly. The node cannot be tagged as "\
  "both a primary (#{deploy_primary_tag}) and a secondary "\
  "(#{deploy_secondary_tag}) node." if is_deploy_primary && is_deploy_secondary
fail "HA controller node is not tagged correctly. The node cannot be tagged as "\
  "a db (#{deploy_db_tag}) node if using external database."\
  if node['ibm-openstack']['ha']['use_external_db'] && is_deploy_db

# Include rewind-service-actions recipe.
# NOTE(wmlynch): It is here so it runs prior to any services notifications.
#                It will only run if the cluster is configured.
include_recipe 'ibm-openstack-ha::rewind-service-actions'

include_recipe 'ibm-openstack-ha::public-endpoint-configure'
# Include base HA controller node recipes.
include_recipe 'ibm-openstack-roles::ha-controller-base'

# Include IBM OpenStack cluster recipes.
# NOTE(rtheis): The cluster setup is only done once on the deploy primary
#               node during the initial deployment.
include_recipe 'ibm-openstack-ha::pacemaker-install'
include_recipe 'ibm-openstack-ha::pacemaker-cluster-setup' unless is_deploy_secondary
include_recipe 'ibm-openstack-ha::pacemaker-configure'
include_recipe 'ibm-openstack-ha::pacemaker-virtualip'

# Include IBM OpenStack load balancing recipes.
include_recipe 'ibm-openstack-ha::haproxy'
include_recipe 'ibm-openstack-ha::pacemaker-haproxy'

# Include IBM OpenStack database recipes.
include_recipe 'ibm-openstack-common::ops-database-server' if is_deploy_db
include_recipe 'ibm-openstack-common::ops-database-openstack-db' if is_deploy_db
include_recipe 'ibm-openstack-ha::db2-hadr-configure' if is_deploy_db
include_recipe 'ibm-openstack-ha::pacemaker-db2' if is_deploy_db
include_recipe 'ibm-openstack-common::ops-database-client'

# Include IBM OpenStack messaging recipes.
include_recipe 'ibm-openstack-common::ops-messaging-server'
include_recipe 'ibm-openstack-common::ops-messaging-client'
include_recipe 'ibm-openstack-ha::rabbitmq-ha-cluster'
include_recipe 'ibm-openstack-ha::pacemaker-rabbitmq'

# Include IBM OpenStack caching recipes.
include_recipe 'ibm-openstack-common::memcached-server'

# Include IBM OpenStack controller selinux recipes.
include_recipe 'ibm-openstack-common::controller-selinux'

# Include IBM OpenStack identity recipes.
include_recipe 'ibm-openstack-simple-token'
include_recipe 'openstack-identity::server'
include_recipe 'openstack-identity::registration'

# Includes IBM OpenStack identity ldap recipes.
include_recipe 'ibm-openstack-common::configure-ldap'

# Include IBM OpenStack image recipes.
include_recipe 'openstack-image::api'
include_recipe 'openstack-image::registry'
include_recipe 'openstack-image::identity_registration'
include_recipe 'openstack-image::image_upload'

# Include IBM OpenStack network recipes.
include_recipe 'openstack-network::identity_registration'
include_recipe 'openstack-network::server'

# Include IBM OpenStack compute recipes.
include_recipe 'openstack-compute::nova-setup'
include_recipe 'openstack-compute::identity_registration'
include_recipe 'openstack-compute::conductor'
include_recipe 'openstack-compute::scheduler'
include_recipe 'openstack-compute::api-os-compute'
include_recipe 'openstack-compute::api-metadata'
include_recipe 'openstack-compute::nova-cert'
include_recipe 'openstack-compute::vncproxy'

# Include IBM OpenStack block storage recipes.
include_recipe 'openstack-block-storage::api'
include_recipe 'openstack-block-storage::scheduler'
include_recipe 'openstack-block-storage::volume'
include_recipe 'openstack-block-storage::identity_registration'
include_recipe 'ibm-openstack-common::cinderv1-endpoint-register'

# Include IBM OpenStack orchestration recipes.
include_recipe 'openstack-orchestration::engine'
include_recipe 'openstack-orchestration::api'
include_recipe 'openstack-orchestration::api-cfn'
include_recipe 'openstack-orchestration::api-cloudwatch'
include_recipe 'openstack-orchestration::identity_registration'

# Include IBM OpenStack telemetry recipes.
include_recipe 'openstack-telemetry::identity_registration'
include_recipe 'openstack-telemetry::agent-central'
include_recipe 'openstack-telemetry::api'
include_recipe 'openstack-telemetry::collector'
include_recipe 'openstack-telemetry::agent-notification'
include_recipe 'openstack-telemetry::alarm-evaluator'
include_recipe 'openstack-telemetry::alarm-notifier'

# Include IBM OpenStack dashboard recipes.
include_recipe 'ibm-openstack-common::dashboard-selinux'
include_recipe 'openstack-dashboard::server'
include_recipe 'ibm-openstack-apache-proxy::apache_proxy_restart'

# Include IBM Self-service portal (SSP) recipes.
if node['ibm-sce']['service']['enabled']
  include_recipe 'ibm-sce::config-sce-policy'
  include_recipe 'ibm-sce::add-sceagent-user'
  include_recipe 'ibm-sce::add-ssp-endpoint'
  include_recipe 'ibm-sce::config-horizon-setting'
  # SSP service recipes, only for primary controller node for now.
  if is_deploy_primary && is_deploy_db
    include_recipe 'ibm-sce::installsce'
    include_recipe 'ibm-sce::add-cloud'
    include_recipe 'ibm-openstack-common::sce-selinux'
  end
  include_recipe 'ibm-sce::install-self-service-ui'
end

# Include IBM OpenStack final cluster recipes.
include_recipe 'ibm-openstack-ha::pacemaker-openstack-controller'
