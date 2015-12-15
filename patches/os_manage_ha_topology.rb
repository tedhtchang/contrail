# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

require File.expand_path(File.dirname(__FILE__) + '/os_manage_common')
require File.expand_path(File.dirname(__FILE__) + '/os_manage_topology')

class Icop
  class Cli
    # Icop::Cli::HATopology is the HA topology data class. It is used
    # to support deployment, update and management of the HA topology.
    class HATopology
      include Chef::Knife::OsManageCommon

      attr_accessor :topology, :ha_controller_nodes, :other_nodes
      attr_accessor :is_ha_primary_tagged

      unless const_defined?(:DEPLOY_HA_PRIMARY)
        DEPLOY_HA_PRIMARY = 'ibm-os-deploy-ha-primary'.freeze
      end
      unless const_defined?(:DEPLOY_HA_SECONDARY)
        DEPLOY_HA_SECONDARY = 'ibm-os-deploy-ha-secondary'.freeze
      end
      unless const_defined?(:DEPLOY_HA_DB_NODE)
        DEPLOY_HA_DB_NODE = 'ibm-os-deploy-ha-db'.freeze
      end
      MAX_HA_DB_NODES = 4.freeze unless const_defined?(:MAX_HA_DB_NODES)

      # Initialize the object.
      def initialize(topology)
        @topology = topology
        @ha_controller_nodes = []
        @other_nodes = []
        @is_ha_primary_tagged = false
        @ha_primary_node = nil
        @number_ha_db_nodes = 0
        @use_external_db = use_external_db?(@topology.environment)

        topology.nodes.each do |node|
          ha_topology_node = HATopologyNode.new(node)
          if ha_topology_node.ha_controller_node?
            @ha_controller_nodes << ha_topology_node
            if ha_topology_node.deploy_ha_primary?
              @is_ha_primary_tagged = true
              @ha_primary_node = ha_topology_node
            end
            @number_ha_db_nodes += 1 if ha_topology_node.deploy_ha_db_node?
          else
            @other_nodes << ha_topology_node
          end
        end

        validate_topology
      end

      # Validate the topology.
      def validate_topology
        # Determine the number of HA controller nodes of each type.
        number_primary_ha_controller_nodes = 0
        number_secondary_ha_controller_nodes = 0
        @ha_controller_nodes.each do | ha_controller_node |
          if ha_controller_node.deploy_ha_primary?
            number_primary_ha_controller_nodes += 1
          elsif ha_controller_node.deploy_ha_secondary?
            number_secondary_ha_controller_nodes += 1
          end
        end

        # Only one primary HA controller node is supported during deployment.
        # Also, the topology must have at least one primary HA controller
        # node if it has at least one secondary HA controller node. New
        # deployments won't have either.
        if number_primary_ha_controller_nodes > 1
          fail "Topology '#{topology.name}' contains multiple primary "\
            "controller nodes. Only one primary controller node is supported."
        elsif number_primary_ha_controller_nodes == 0 &&
          number_secondary_ha_controller_nodes > 0
          fail "Topology '#{topology.name}' does not have a primary "\
            "controller node. At least one primary controller node is "\
            "required."
        end
        # The primary HA node (if there is one and not using external DB),
        # it must be tagged as a DB node.
        # No more than 4 DB nodes are supported.
        # Also, the topology must have a primary HA node if it has at
        # least one HA DB node. New deployments won't have either.
        if !(@ha_primary_node.nil? || @ha_primary_node.deploy_ha_db_node?) &&
          !@use_external_db
          fail "Topology '#{topology.name}' contains a primary controller "\
              "'#{@ha_primary_node.name}' that is not a database node. The "\
              "primary node must also be a database node." \
        end
        if @number_ha_db_nodes > MAX_HA_DB_NODES
          fail "Topology '#{topology.name}' contains more than "\
            "#{MAX_HA_DB_NODES} database nodes. Only "\
            "#{MAX_HA_DB_NODES} database nodes are supported."
        elsif number_primary_ha_controller_nodes == 0 &&
          @number_ha_db_nodes > 0
          fail "Topology '#{topology.name}' does not have a primary "\
            "controller node. One primary controller node is required."
        end
      end

      # Prepare the topology for deployment. Optionally enable or disable
      # database tagging of the nodes.
      def prepare_for_deployment(database_tagging_enabled = true)
        # Tag all HA controller nodes as either primary or secondary.
        # For new deployments, the first node will be the primary.
        # The next three nodes will be tagged as DB secondary, if not using
        # external DB
        @ha_controller_nodes.each_with_index do | ha_controller_node, index |
          unless ha_controller_node.deploy_ha_primary? ||
            ha_controller_node.deploy_ha_secondary?
            if @is_ha_primary_tagged
              ha_controller_node.tag_node([DEPLOY_HA_SECONDARY])
            else
              if @use_external_db
                ha_controller_node.tag_node([DEPLOY_HA_PRIMARY])
              else
                ha_controller_node.tag_node([DEPLOY_HA_PRIMARY,
                                             DEPLOY_HA_DB_NODE])
                @number_ha_db_nodes += 1
              end
              @is_ha_primary_tagged = true
              @ha_primary_node = ha_controller_node
            end
          end

          if @use_external_db && database_tagging_enabled
            database_tagging_enabled = false
          end
          unless ha_controller_node.deploy_ha_primary? ||
            ha_controller_node.deploy_ha_db_node?
            if database_tagging_enabled && @is_ha_primary_tagged &&
                @number_ha_db_nodes < MAX_HA_DB_NODES
              ha_controller_node.tag_node([DEPLOY_HA_DB_NODE])
              @number_ha_db_nodes += 1
            end
          end
        end
        # Ensure search indexes for node tags are current
        refresh_search_indexes
      end

      # Wait up to 3 minutes for the HA controller node to be indexed
      # for search.  This should normally take less than a minute.  This is
      # shared by ha controller deploy, where we know we got inconsistent
      # search results just after tagging the nodes, and occasionally when
      # deploying compute nodes, possibly because the ha controllers nodes
      # are rewritten to the chef server as the chef-client runs complete.
      def refresh_search_indexes
        puts('Preparing node search index for deployment ...')
        18.times do | count |
          nodes_found = search_for_nodes(
            topology.environment,
            Icop::Cli::Constants::IBM_OS_HA_CONTROLLER_NODE,
            [DEPLOY_HA_PRIMARY, DEPLOY_HA_SECONDARY]) or \
          nodes_found = search_for_nodes(
            topology.environment,
            Icop::Cli::Constants::IBM_OS_HA_CONTROLLER_NODE_WITHOUT_ML2_PLUGIN,
            [DEPLOY_HA_PRIMARY, DEPLOY_HA_SECONDARY])
          break if nodes_found.size >= @ha_controller_nodes.size
          sleep(10)
        end
      end

      # For all nodes in the topology, return a sorted hash with
      # run_order_number as the key and an array of topology nodes
      # with that run_order_number as values.
      def run_sequence_all_nodes
        @topology.run_sequence
      end

      # From the HA controller nodes in the topology, return an array
      # of topology nodes with the primary node as the first node.
      def run_sequence_ha_controller_nodes
        ha_controller_nodes_run_sequence = []
        @ha_controller_nodes.each do | ha_controller_node |
          topology_node = ha_controller_node.topology_node
          if ha_controller_node.deploy_ha_primary?
            ha_controller_nodes_run_sequence.unshift(topology_node)
          else
            ha_controller_nodes_run_sequence << topology_node
          end
        end
        ha_controller_nodes_run_sequence
      end

      # For the other nodes (i.e. non HA controller nodes) in the topology,
      # return a sorted hash with run_order_number as the key and an array
      # of topology nodes with that run_order_number as values.
      def run_sequence_other_nodes
        other_nodes_run_sequence = {}
        @other_nodes.each do | other_node |
          topology_node = other_node.topology_node
          run_order_number = topology_node.run_order_number
          unless other_nodes_run_sequence.key?(run_order_number)
            other_nodes_run_sequence[run_order_number] = []
          end
          other_nodes_run_sequence[run_order_number] << topology_node
        end
        other_nodes_run_sequence.sort
      end
    end

    # Icop::Cli::HATopologyNode is the HA topology node data class. It is used
    # to support an HA topology.
    class HATopologyNode
      include Chef::Knife::OsManageCommon

      attr_accessor :topology_node, :tags, :name

      # Initialize the object.
      def initialize(topology_node)
        @topology_node = topology_node
        @tags = list_node_tags(topology_node.chef_node_name)
        @name = topology_node.chef_node_name
        validate_tags
      end

      # Validate the node tags
      def validate_tags
        if deploy_ha_primary? && deploy_ha_secondary?
          fail "Deployment tags for node '#{@topology_node.fqdn}' are not "\
            "valid. The node can not be both a primary controller node and a "\
            "secondary controller node."
        end
        if deploy_ha_primary? && !deploy_ha_db_node? &&
          !use_external_db?(@topology_node.environment)
          fail "Deployment tags for node '#{@topology_node.fqdn}' are not "\
            "valid. A primary controller must also be database node."
        end
      end

      # Is HA controller node?
      def ha_controller_node?
        used_ha_roles = @topology_node.runlist & \
          Icop::Cli::Constants::ROLE_IBM_OS_HA_CONTROLLER_NODE
        if used_ha_roles.size == 1
          return true
        else
          return false
        end
      end

      # Is deploy HA primary node?
      def deploy_ha_primary?
        @tags.include?(Icop::Cli::HATopology::DEPLOY_HA_PRIMARY)
      end

      # Is deploy HA secondary node?
      def deploy_ha_secondary?
        @tags.include?(Icop::Cli::HATopology::DEPLOY_HA_SECONDARY)
      end

      # Is deploy HA DB node?
      def deploy_ha_db_node?
        @tags.include?(Icop::Cli::HATopology::DEPLOY_HA_DB_NODE)
      end

      # Tag the node.
      def tag_node(tags_to_create)
        create_node_tags(@topology_node.chef_node_name, tags_to_create)
        @tags = list_node_tags(@topology_node.chef_node_name)
      end
    end
  end
end
