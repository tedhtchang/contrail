# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014, 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

name 'ibm-os-single-controller-basic-node'
description 'IBM OpenStack Single Controller Node role'
run_list(
  'role[ibm-os-base]',
  'role[ibm-os-database-server-node]',
  'role[ibm-os-messaging-server-node]',
  'role[ibm-os-messaging-client-node]',
  'role[ibm-os-cache-server-node]',
  'recipe[ibm-openstack-common::controller-selinux]',
  'recipe[ibm-openstack-simple-token]',
  'role[os-identity]',
  'recipe[ibm-openstack-common::configure-ldap]',
  'role[os-image]',
  'recipe[openstack-network::identity_registration]',
  'recipe[ibm-openstack-network::balancer]',
  'role[os-network-server]',
  'role[os-compute-setup]',
  'role[os-compute-conductor]',
  'role[os-compute-scheduler]',
  'role[os-compute-api-os-compute]',
  'role[os-compute-api-metadata]',
  'role[os-compute-cert]',
  'role[os-compute-vncproxy]',
  'recipe[openstack-compute::serialproxy]',
  'role[os-block-storage]',
  'recipe[ibm-openstack-common::cinderv1-endpoint-register]',
  'role[os-orchestration]',
  'role[os-telemetry-agent-central]',
  'role[os-telemetry-api]',
  'role[os-telemetry-collector]',
  'role[os-telemetry-agent-notification]',
  'role[os-telemetry-alarm-evaluator]',
  'role[os-telemetry-alarm-notifier]',
  'role[os-bare-metal-api]',
  'role[ibm-os-client-node]',
  'role[ibm-os-dashboard-node]',
  'recipe[ibm-sce::config-sce-policy]',
  'recipe[ibm-sce::add-sceagent-user]',
  'recipe[ibm-sce::add-ssp-endpoint]',
  'recipe[ibm-sce::config-horizon-setting]'
)
