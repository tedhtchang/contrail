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
# Cookbook Name:: ibm-openstack-ha
# Recipe: rewind-service-actions

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['roles'].include?('ibm-os-ha-controller-node-without-ml2-plugin')
  tmp_ha_services = node['ibm-openstack']['ha']['pacemaker']['cluster']['managed']['services_to_rewind'].dup
  ml2_agents = ['service[neutron-plugin-openvswitch-agent]',
                'service[neutron-metadata-agent]',
                'service[neutron-l3-agent]',
                'service[neutron-dhcp-agent]']
  ml2_agents.each do |deleted_agent|
    if tmp_ha_services.include?(deleted_agent)
      tmp_ha_services.delete(deleted_agent)
    end
  end

  node.override['ibm-openstack']['ha']['pacemaker']['cluster']['managed']['services_to_rewind'] = tmp_ha_services
end

ha_pacemaker_options = node['ibm-openstack']['ha']['pacemaker']
ha_services = ha_pacemaker_options['cluster']['managed']['services_to_rewind']
rabbitmq_service = "service[#{node['rabbitmq']['service_name']}]"

# Do not remove immediate notifications for the rabbitmq service.
ha_notification_services = ha_services.dup
ha_notification_services.delete(rabbitmq_service)

# Use Chef to rewind actions for services managed by pacemaker.
ruby_block 'rewind pacemaker managed services' do # :pragma-foodcritic: ~FC014
  block do
    #--------------------------------------------------------------------------
    # During initial deployment, the node won't be part of an HA
    # cluster and most actions are allowed on the services managed by
    # pacemaker. The exceptions are:
    #   1) The enable service action is always changed to disable.
    #   2) Immediate notification actions on the service are ignored for
    #      secondary HA controller nodes.  Such actions aren't necessary since
    #      the services on the primary HA controller node can be used during
    #      deployment.  This enables deploy performance improvements.
    #   3) Delayed notification actions on the service are ignored.
    #   4) Delayed notification stop actions are added to all services
    #      for secondary HA controller nodes. This prevents race conditions
    #      and long recovery intervals when adding the secondary HA controller
    #      nodes to the cluster.
    #
    # During update of a node, the expectation is for the node to be
    # placed in standby mode thus stopping all active services.
    # As a result, no service actions (except disable) or notifications
    # are necessary since an unstandby action is expected to be done
    # after the update thus allowing services to run on the node again
    # and pick up any changes made.
    #--------------------------------------------------------------------------
    # Retrieve the 'ready' boolean
    ha_ready = node['ibm-openstack']['ha']['pacemaker']['cluster']['node']['ready']
    # The cluster is configured if the file exists and ha_ready is set to true
    ha_cluster_configured = File.exists?('/etc/corosync/corosync.conf') && ha_ready
    deploy_ha_primary_node = deploy_ha_primary?

    puts("\nRewinding actions for services managed by pacemaker")

    # Ignore all immediate notifications when this node is part of an
    # HA cluster.  Also, ignore immediate notifications for OpenStack services
    # on secondary HA controller nodes.
    if ha_cluster_configured || !deploy_ha_primary_node
      puts('Ignoring immediate notifications for services managed by pacemaker.')
      run_context.immediate_notification_collection.each do |k, n_list|
        n_list.each do | n |
          if ha_notification_services.include?(n.resource.to_s)
            # Change action to :nothing
            n.action = :nothing
          end
        end
      end
    end

    # Ignore all deplayed notifications.
    puts('Ignoring delayed notifications for services managed by pacemaker.')
    run_context.delayed_notification_collection.each do |k, n_list|
      n_list.each do | n |
        if ha_services.include?(n.resource.to_s)
          # Change action to :nothing
          n.action = :nothing
        end
      end
    end

    # Add a stop delayed notification when the node is not part of
    # an HA cluster and is not the deployment primary.  This will
    # prepare the node to be added to the HA cluster.
    if !ha_cluster_configured && !deploy_ha_primary_node
      puts('Adding delayed stop notification for services managed by pacemaker.')
      ha_services.each do |ha_service|
        run_context.notifies_delayed(Chef::Resource::Notification.new(resources(ha_service), :stop, self))
      end
    end

    # Rewind service actions based on the HA cluster status.
    puts('Rewinding service actions for services managed by pacemaker.')
    ha_services.each do |ha_service|
      # Allow all actions except enable when the node is not part of an
      # HA cluster and it is the deployment primary OR if the service is
      # for RabbitMQ.
      if (!ha_cluster_configured && deploy_ha_primary_node) || ha_service == rabbitmq_service
        current_actions = resources(ha_service).action
        current_actions.delete(:enable) if current_actions.include?(:enable)
        current_actions << :disable unless current_actions.include?(:disable)
        resources(ha_service).action(current_actions)
      # Only allow the disable action when the node is part of an HA cluster.
      else
        resources(ha_service).action(:disable)
      end
    end
  end
  only_if { node['ibm-openstack']['ha']['pacemaker']['cluster']['managed']['service_rewind_enabled'] }
end
