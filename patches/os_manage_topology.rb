# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014, 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

require File.expand_path(File.dirname(__FILE__) + '/os_manage_common')
require File.expand_path(File.dirname(__FILE__) + '/os_manage_node')

class Icop
  class Cli
    # Icop::Cli::Topology is the topology data class. The Topology is created
    # from a JSON file input.
    #
    # Topology JSON example:
    # <tt>
    # {
    # "name":"Topology1",
    # "description":"This is a topology",
    # "environment":"single-controller-n-compute",
    # "fips_compliance":true,
    # "secret_file":"/root/whatever",
    # "cacert_file":"/root/cacert.pem",
    # "run_sequentially":true,
    # "concurrency":10,
    # "nodes": [
    #   {
    #   "name": "Node1",
    #   "description": "This is a node",
    #   "fqdn":"host1.company.com",
    #   "user":"root",
    #   "password":"passw0rd",
    #   "chef_client_options": [
    #     "-i 3600",
    #     "-s 600"
    #     ],
    #   "run_order_number":1,
    #   "concurrency": 2
    #   "quit_on_error":true,
    #   "cert_file":"/root/cert.pem",
    #   "key_file":"/root/key.pem",
    #   "template_file":"bootstrap/ibm-os-chef-full.erb"
    #   "runlist": [
    #     "role[roleA]",
    #     "recipe[recipeA]",
    #     "role[roleB]"
    #     ],
    #   "attributes": "{\"whatever\": \"dude\",\"howdy\":\"partner\"}"
    #   },
    #   {
    #   "name": "Node2",
    #   "chef_node_name": "Host2_Node",
    #   "description": "Another node",
    #   "fqdn":"host2.company.com",
    #   "identity_file":"/root/whatever",
    #   "run_order_number":2,
    #   "run_sequentially": false
    #   "distro":"my_distro",
    #   "allow_update":false
    #   "attribute_file":"/root/attributes.json",
    #   "runlist": [
    #     "role[roleC]"
    #     ]
    #   }
    # ]
    # }
    # </tt>
    # Required: environment, nodes, fqdn, password or identity_file, runlist
    class Topology
      include Chef::Knife::OsManageCommon

      attr_accessor :name, :description, :run_sequentially, :secret_file
      attr_accessor :nodes, :concurrency, :environment, :orchestration
      attr_accessor :fips, :cacert_file, :json_file_name, :virtual_ip

      unless const_defined?(:ORCHESTRATION_RUN_ORDER_NUMBER)
        ORCHESTRATION_RUN_ORDER_NUMBER = 'run_order_number'.freeze
      end
      unless const_defined?(:ORCHESTRATION_HA_CONTROLLER_N_COMPUTE)
        ORCHESTRATION_HA_CONTROLLER_N_COMPUTE =
          Icop::Cli::Constants::ORCHESTRATION_HA_CONTROLLER_N_COMPUTE.freeze
      end
      unless const_defined?(:MINIMUM_HA_CONTROLLER_NODES)
        MINIMUM_HA_CONTROLLER_NODES =
          Icop::Cli::Constants::MIN_HA_CONTROLLERS.freeze
      end
      unless const_defined?(:MAXIMUM_PARALLEL_NODES)
        MAXIMUM_PARALLEL_NODES =
          Icop::Cli::Constants::MAX_PARALLEL_NODES.freeze
      end
      def initialize
        # Optional
        @run_sequentially = Icop::Cli::Constants::DEFAULT_RUN_SEQUENTIALLY
        # Optional
        @fips = false
        # Optional
        @orchestration = ORCHESTRATION_RUN_ORDER_NUMBER
        @nodes = []
      end

      # Create the Topology object from the specified JSON file. Returns the
      # Topology object. The Topology is validated before being returned.
      def self.from_file(name)
        topology_json = load_json_hash_from_file(name)
        validate_topology_json_hash(topology_json, name)
        create_from_json_hash(topology_json, name)
      end

      # Load the topology JSON file with the specified name. Returns the
      # Topology JSON Hash.
      def self.load_json_hash_from_file(name)
        json_file = get_json_filename(name)
        unless File.exist?(json_file)
          fail "Topology file '#{json_file}' could not be loaded from disk."
        end
        Chef::JSONCompat.from_json(IO.read(json_file))
      end

      # The topology file specified can optionally contain the path and/or
      # the extension. If the name specified cannot be found in the known
      # topology search path, and an extension was not specified, the
      # name+'.json' will also be attempted.
      def self.get_json_filename(fname)
        topology_file = fname.dup
        topology_file = new.find_topology_file(topology_file)
        if topology_file
          fname = topology_file
        else
          fname = File.join(File.dirname(fname), File.basename(fname))
          unless File.exist?(fname)
            unless File.extname(fname).length > 0
              fname = "#{fname}.json" if File.exist?("#{fname}.json")
            end
          end
        end
        fname
      end

      # Validate the specified topology file.
      def self.validate_topology_json_hash(topology_json, file_name)
        unless topology_json.is_a?(Hash) && topology_json['environment']\
            && topology_json['nodes']
          fail_msg = "The '#{file_name}' is not a valid topology file."
          fail_msg << ' And it seems to be an environment file.'\
            if topology_json.class.to_s == 'Chef::Environment'
          fail fail_msg
        end
      end

      # Create a new Topology object from the specified JSON Hash. Returns the
      # Topology object.  The Topology is validated before being returned.
      # The secret_file value can be defaulted via the command line option
      # or the config.
      def self.create_from_json_hash(o, file_name)
        topology = new
        topology.json_file_name = file_name
        topology = initialize_topology(topology, o)
        topology
      end

      # Create a Node from a hash, and return the Node
      def self.create_node_from_hash(n)
        node = Icop::Cli::Node.create_from_json_hash(n)
        node
      end

      # Initialize the topology from the specified hash, and return the
      # topology
      def self.initialize_topology(topology, o)
        topology.name = o['name']
        topology.description = o['description']
        topology.environment = o['environment']
        topology.fips = o['fips_compliance'] if o['fips_compliance']
        # The virtual_ip is retrieved from the environment later. It is not
        # passed in via the topology JSON.
        topology.secret_file = o['secret_file']
        topology.concurrency = MAXIMUM_PARALLEL_NODES
        topology.concurrency = o['concurrency'] if o['concurrency']
        topology.run_sequentially =
          o['run_sequentially'] if o['run_sequentially']
        topology.orchestration =
          o['orchestration'] if o['orchestration']
        topology.cacert_file = o['cacert_file']
        if o['nodes'] && o['nodes'].is_a?(Array)
          o['nodes'].each do |n|
            node = create_node_from_hash(n)
            topology.nodes << node
          end
        end
        topology.validate

        # Add secret_file, environment, fips, and cacert_file to each node for
        # processing later after validation
        topology.nodes.each do | node |
          node.secret_file = topology.secret_file
          node.environment = topology.environment
          node.json_file_name = topology.json_file_name
          node.fips = topology.fips
          node.cacert_file = topology.cacert_file
        end
        topology
      end

      # From the whole topology, return a sorted hash with run_order_number as
      # the key and an array of nodes with that run_order_number as values
      def run_sequence
        nodes_by_run_order_number = {}
        nodes.each do | node |
          unless nodes_by_run_order_number.key?(node.run_order_number)
            nodes_by_run_order_number[node.run_order_number] = []
          end
          nodes_by_run_order_number[node.run_order_number] << node
        end
        nodes_by_run_order_number.sort
      end

      # Returns the adjusted run_sequentially value for the specified array of
      # nodes for a particular run_order_number. The nodes can override the
      # run_sequentially value for a particular run_order_number group of
      # nodes. If the run_sequntually value is set for any of the nodes and it
      # is different than the topology's run_sequentially setting, return the
      # value for that node. Otherwise, the topology's run_sequentially value
      # is returned.
      def adjusted_run_sequentially_value(nodes)
        nodes.each do | node |
          unless node.run_sequentially.nil?
            return node.run_sequentially if node.run_sequentially !=
              run_sequentially
          end
        end
        run_sequentially
      end

      # Returns the adjusted concurrency value for the specified array of
      # nodes for a particular run_order_number. The nodes can override the
      # concurrency value for a particular run_order_number group of
      # nodes. If the concurrency value is set for any of the nodes, the
      # smallest concurrency setting of the nodes or the topology is returned.
      # Otherwise, the topology's concurrency value is returned.
      def adjusted_concurrency_value(nodes)
        smallest_concurrency = concurrency
        nodes.each do | node |
          unless node.concurrency.nil?
            smallest_concurrency = node.concurrency if node.concurrency <
              smallest_concurrency
          end
        end
        smallest_concurrency
      end

      # Validate the topology values. Raise an exception if required values are
      # missing, or if values are not valid.
      def validate
        validate_no_duplicate_fqdn
        validate_environment
        validate_run_sequentially
        validate_concurrency
        validate_secret_file
        validate_nodes
        validate_orchestration
        validate_cacert_file
      end

      # Make sure a node fqdn is not duplicated in a run_order_number
      def validate_no_duplicate_fqdn
        runs = run_sequence
        runs.map do | run_number, nodes|
          fqdns = []
          nodes.each do | node |
            if fqdns.include?(node.fqdn)
              fail "The topology run_order_number '#{run_number}' contains"\
                " more than one node fqdn value of '#{node.fqdn}'."
            end
            fqdns << node.fqdn
          end
        end
      end

      # Validate that the topology environment was specified
      def validate_environment
        unless environment
          fail "The topology #{display_name(name)}environment value must be"\
            " specified."
        end
      end

      # The run_sequentially value must be either true or false
      def validate_run_sequentially
        unless !!run_sequentially == run_sequentially
          fail 'The topology run_sequentially value must be a boolean type"\
          " set to true or false.'
        end
      end

      # If the optional concurrency number is specified, verify that it is
      # an integer value greater than zero.
      def validate_concurrency
        if concurrency
          begin
            Integer concurrency
            fail if concurrency < 1
          rescue
            raise "The topology concurrency value must be an integer greater"\
              " than zero."
          end
        end
      end

      # If the topology secret file is specified, verify that the file exists
      def validate_secret_file
        if secret_file
          unless File.exist?(secret_file)
            fail "The topology #{display_name(name)}secret_file"\
              " '#{secret_file}' cannot be found."
          end
        end
      end

      # Make sure there is at least one node defined in the topology
      def validate_nodes
        unless nodes.length > 0
          fail 'The topology nodes value must not be empty.'
        end
      end

      # If the topology orchestration is specified, verify that it is valid.
      def validate_orchestration
        unless orchestration_types.include?(orchestration)
          fail "The topology orchestration value '#{orchestration}' is "\
            "not valid."
        end
        validate_orchestration_ha_controller_n_compute
      end

      # Returns the valid topology orchestration types.
      def orchestration_types
        [ORCHESTRATION_RUN_ORDER_NUMBER, ORCHESTRATION_HA_CONTROLLER_N_COMPUTE]
      end

      # Verify HA controller + n compute topology orchestration.
      def validate_orchestration_ha_controller_n_compute
        is_first_run_order_number = true
        number_ha_controller_nodes = 0
        nodes_incorrect_run_order_number = []

        # Loop through the run sequence to count the number of HA controller
        # nodes and to ensure that the HA controller nodes have the lowest
        # and same run order number.
        runs = run_sequence
        allowed_ha_roles=Icop::Cli::Constants::ROLE_IBM_OS_HA_CONTROLLER_NODE
        runs.map do | run_order_number, nodes |
          first_ha_role = nil
          nodes.each do | node |
            used_ha_roles = node.runlist & allowed_ha_roles
            if used_ha_roles.size == 1
              if first_ha_role.nil?
                first_ha_role = used_ha_roles[0]
                is_ha_controller_node = true
              elsif first_ha_role == used_ha_roles[0]
                is_ha_controller_node = true
              else
                is_ha_controller_node = false
              end
            else
              is_ha_controller_node = false
            end

            if is_ha_controller_node
              number_ha_controller_nodes += 1
              nodes_incorrect_run_order_number << node.fqdn\
                unless is_first_run_order_number
            else
              nodes_incorrect_run_order_number << node.fqdn\
                if is_first_run_order_number
            end
          end
          is_first_run_order_number = false
        end

        if orchestration == ORCHESTRATION_HA_CONTROLLER_N_COMPUTE
          # Fail if there are too few HA controller nodes.
          fail "The topology has #{number_ha_controller_nodes} controller "\
            "nodes when at least #{MINIMUM_HA_CONTROLLER_NODES} are required."\
            if number_ha_controller_nodes < MINIMUM_HA_CONTROLLER_NODES

          # Fail if any nodes have an incorrect run order number.
          fail "The topology requires all controller nodes to have the same "\
            "and lowest run_order_number. The run_order_number for the "\
            "following nodes is not correct: "\
            "#{nodes_incorrect_run_order_number}."\
            unless nodes_incorrect_run_order_number.empty?
        elsif number_ha_controller_nodes > 0
          # Fail if orchestration doesn't match topology.
          fail "The topology orchestration value must be "\
            "'#{ORCHESTRATION_HA_CONTROLLER_N_COMPUTE}' when a node's "\
            "run_list includes "\
            "'#{Icop::Cli::Constants::ROLE_IBM_OS_HA_CONTROLLER_NODE}'."
        end
      end

      # If the topology cacert file is specified, and fips is set, verify that
      # the cacert file exists
      def validate_cacert_file
        return unless fips
        if cacert_file
          unless File.exist?(cacert_file)
            fail "The topology #{display_name(name)}cacert_file"\
              " '#{cacert_file}' cannot be found."
          end
        end
      end

      # Convert Topology to hash. Remove the nodes hash from the topology. Only
      # return the part of the topology that does not include the nodes.
      def to_hash
        hash = Hash[
          instance_variables.map do |var|
            [var[1..-1].to_s.delete('@'), instance_variable_get(var)]
          end]
        hash.delete('nodes')
        hash
      end
    end
  end
end

class Icop
  class Cli
    # Icop::Cli::UpdateTopology is the topology data class used to updates.
    # Some of the topology validation methods are different for updates.
    # The UpdateTopology is created from a JSON file input.
    #
    # Required: nodes, fqdn, password or identity_file
    class UpdateTopology < Topology
      # Create a new UpdateTopology object from the specified JSON Hash.
      # Returns the UpdateTopology object.  The UpdateTopology is validated
      # before being returned.
      def self.create_from_json_hash(o, file_name)
        topology = new
        topology.json_file_name = file_name
        topology = initialize_topology(topology, o)
        topology
      end

      # Create an UpdateNode from a hash, and return the UpdateNode
      def self.create_node_from_hash(n)
        node = Icop::Cli::UpdateNode.create_from_json_hash(n)
        node
      end

      # Validate the topology values for an update. Raise an exception if
      # required values are missing, or if values are not valid.
      def validate
        validate_no_duplicate_fqdn
        validate_run_sequentially
        validate_concurrency
        validate_nodes
        validate_orchestration
        # Do not validate_cacert_file during an update.
      end
    end
  end
end
