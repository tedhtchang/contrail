# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014, 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

class Icop
  class Cli
    # Icop::Cli::Constants contains constants used by the ICOP CLI
    class Constants
      unless const_defined?(:DEFAULT_DISTRO)
        DEFAULT_DISTRO = 'ibm-os-chef-full'.freeze
      end
      unless const_defined?(:DEFAULT_UPDATE_DISTRO)
        DEFAULT_UPDATE_DISTRO = 'ibm-os-manage-update-chef-full'.freeze
      end
      unless const_defined?(:DEFAULT_WIN_DISTRO)
        DEFAULT_WIN_DISTRO = 'ibm-os-windows-chef-client-msi'.freeze
      end
      unless const_defined?(:DEFAULT_WIN_UPDATE_DISTRO)
        DEFAULT_WIN_UPDATE_DISTRO =
          'ibm-os-windows-update-chef-client-msi'.freeze
      end
      DEFAULT_USER = 'root'.freeze unless const_defined?(:DEFAULT_USER)
      unless const_defined?(:DEFAULT_WIN_USER)
        DEFAULT_WIN_USER = 'Administrator'.freeze
      end
      DEPLOY_CMD = 'chef-client'.freeze unless const_defined?(:DEPLOY_CMD)
      UPDATE_CMD = 'chef-client'.freeze unless const_defined?(:UPDATE_CMD)
      unless const_defined?(:BOOTSTRAP_FOLDER)
        BOOTSTRAP_FOLDER = 'bootstrap'.freeze
      end
      unless const_defined?(:DATA_BAGS_FOLDER)
        DATA_BAGS_FOLDER = 'data_bags'.freeze
      end
      unless const_defined?(:EXAMPLE_DATA_BAG_SECRET_FILE)
        EXAMPLE_DATA_BAG_SECRET_FILE = 'example_data_bag_secret'.freeze
      end
      unless const_defined?(:DEFAULT_TEMPLATE_FILE)
        DEFAULT_TEMPLATE_FILE = 'ibm-os-chef-full.erb'.freeze
      end
      unless const_defined?(:DEFAULT_WIN_TEMPLATE_FILE)
        DEFAULT_WIN_TEMPLATE_FILE = 'ibm-os-windows-chef-client-msi.erb'.freeze
      end
      unless const_defined?(:DEFAULT_UPDATE_TEMPLATE_FILE)
        DEFAULT_UPDATE_TEMPLATE_FILE =
          'ibm-os-manage-update-chef-full.erb'.freeze
      end
      unless const_defined?(:DEFAULT_WIN_UPDATE_TEMPLATE_FILE)
        DEFAULT_WIN_UPDATE_TEMPLATE_FILE =
          'ibm-os-windows-update-chef-client-msi.erb'.freeze
      end
      unless const_defined?(:DISPLAY_COLUMN_LIMIT)
        DISPLAY_COLUMN_LIMIT = 100.freeze
      end
      unless const_defined?(:DISPLAY_NUM_COLUMNS)
        DISPLAY_NUM_COLUMNS = 3.freeze
      end
      unless const_defined?(:RELATIVE_CONFIG_PATH)
        RELATIVE_CONFIG_PATH = '../cli/config'.freeze
      end
      unless const_defined?(:RELATIVE_TOPOLOGIES_PATH)
        RELATIVE_TOPOLOGIES_PATH = 'topologies'.freeze
      end
      NODELOG_MAX_FILES = 44.freeze unless const_defined?(:NODELOG_MAX_FILES)
      unless const_defined?(:NODELOG_PATH)
        NODELOG_PATH = '/var/log/icm-deployer/nodes'.freeze
      end
      KEY = 'L/7Za3x/hS8OP9+b5qPDJw=='.freeze unless const_defined?(:KEY)
      IV = ':3tE5vpzUDTAGmo64nNeSvQ=='.freeze unless const_defined?(:IV)
      ENVIRONMENTS_FOLDER = 'environments'.freeze \
          unless const_defined?(:ENVIRONMENTS_FOLDER)
      unless const_defined?(:DB_PASSWORDS_DATA_BAG)
        DB_PASSWORDS_DATA_BAG = 'db_passwords'.freeze
      end
      unless const_defined?(:SECRETS_DATA_BAG)
        SECRETS_DATA_BAG = 'secrets'.freeze
      end
      unless const_defined?(:SERVICE_PASSWORDS_DATA_BAG)
        SERVICE_PASSWORDS_DATA_BAG = 'service_passwords'.freeze
      end
      unless const_defined?(:USER_PASSWORDS_DATA_BAG)
        USER_PASSWORDS_DATA_BAG = 'user_passwords'.freeze
      end
      unless const_defined?(:DATA_BAG_ATTR_SUFFIX)
        DATA_BAG_ATTR_SUFFIX = '_data_bag'.freeze
      end
      unless const_defined?(:DB_PASSWORDS_DATA_BAG_ATTR)
        DB_PASSWORDS_DATA_BAG_ATTR =
          "#{DB_PASSWORDS_DATA_BAG}#{DATA_BAG_ATTR_SUFFIX}".freeze
      end
      unless const_defined?(:SECRETS_DATA_BAG_ATTR)
        SECRETS_DATA_BAG_ATTR =
          "#{SECRETS_DATA_BAG}#{DATA_BAG_ATTR_SUFFIX}".freeze
      end
      unless const_defined?(:SERVICE_PASSWORDS_DATA_BAG_ATTR)
        SERVICE_PASSWORDS_DATA_BAG_ATTR =
          "#{SERVICE_PASSWORDS_DATA_BAG}#{DATA_BAG_ATTR_SUFFIX}".freeze
      end
      unless const_defined?(:USER_PASSWORDS_DATA_BAG_ATTR)
        USER_PASSWORDS_DATA_BAG_ATTR =
          "#{USER_PASSWORDS_DATA_BAG}#{DATA_BAG_ATTR_SUFFIX}".freeze
      end
      unless const_defined?(:VIRTUALIP_ATTR_ARRAY)
        VIRTUALIP_ATTR_ARRAY = %w(ibm-openstack ha virtualip address).freeze
      end

      # Constants used by 'os manage services'
      SCRIPTS_FOLDER = 'scripts'.freeze unless const_defined?(:SCRIPTS_FOLDER)
      unless const_defined?(:DEFAULT_SERVICES_SCRIPT_TEMPLATE_FILE)
        DEFAULT_SERVICES_SCRIPT_TEMPLATE_FILE =
          'cmwo_services_template.erb'.freeze
      end
      unless const_defined?(:DEFAULT_SERVICES_SCRIPT)
        DEFAULT_SERVICES_SCRIPT = '/etc/cmwo_services.sh'.freeze
      end

      # Constants for deploy cloud templates
      unless const_defined?(:DEFAULT_ENV_YAML_TEMPLATE_FILE)
        DEFAULT_ENV_YAML_TEMPLATE_FILE = 'env_yml_template.erb'.freeze
      end
      unless const_defined?(:DEFAULT_NODE_ATTRIBUTES_JSON_TEMPLATE_FILE)
        DEFAULT_NODE_ATTRIBUTES_JSON_TEMPLATE_FILE =
          'node_attributes_json_template.erb'.freeze
      end
      unless const_defined?(:DEFAULT_TOPOLOGY_JSON_TEMPLATE_FILE)
        DEFAULT_TOPOLOGY_JSON_TEMPLATE_FILE =
          'topology_json_template.erb'.freeze
      end
      unless const_defined?(:CHEF_CLIENT_BOOTSTRAP_FUNCTION)
        CHEF_CLIENT_BOOTSTRAP_FUNCTION = 'Bootstrapping Node'
      end
      unless const_defined?(:CHEF_CLIENT_CONVERGE_FUNCTION)
        CHEF_CLIENT_CONVERGE_FUNCTION = 'Converging Node'
      end

      # Constants used during update
      unless const_defined?(:UPDATE_REMOTE_JSON_NODE_ATTRIBUTES_FILE)
        UPDATE_REMOTE_JSON_NODE_ATTRIBUTES_FILE =
          '/etc/chef/update.json'.freeze
      end

      # Constants for roles.
      unless const_defined?(:IBM_OS_HA_CONTROLLER_NODE)
        IBM_OS_HA_CONTROLLER_NODE = 'ibm-os-ha-controller-node'.freeze
      end

      unless const_defined?(:IBM_OS_HA_CONTROLLER_NODE_WITHOUT_ML2_PLUGIN)
        IBM_OS_HA_CONTROLLER_NODE_WITHOUT_ML2_PLUGIN = \
          'ibm-os-ha-controller-node-without-ml2-plugin'.freeze
      end

      unless const_defined?(:ROLE_IBM_OS_HA_CONTROLLER_NODE)
        ROLE_IBM_OS_HA_CONTROLLER_NODE = [
          "role[#{IBM_OS_HA_CONTROLLER_NODE}]",
          "role[#{IBM_OS_HA_CONTROLLER_NODE_WITHOUT_ML2_PLUGIN}]"]
      end

      unless const_defined?(:ORCHESTRATION_HA_CONTROLLER_N_COMPUTE)
        ORCHESTRATION_HA_CONTROLLER_N_COMPUTE =
          'ha_controller_n_compute'.freeze
      end

      # Constants used for SSL certificate and vault management
      unless const_defined?(:DEFAULT_CA_YAML_FILE_NAME)
        DEFAULT_CA_YAML_FILE_NAME = 'ca.yml'.freeze
      end
      unless const_defined?(:DEFAULT_NODE_TYPES_YAML_FILE_NAME)
        DEFAULT_NODE_TYPES_YAML_FILE_NAME = 'node_types.yml'.freeze
      end
      unless const_defined?(:DEFAULT_CERTS_TARGET_PATH)
        DEFAULT_CERTS_TARGET_PATH = '/etc/pki/tls/icm/certs'.freeze
      end
      unless const_defined?(:DEFAULT_KEY_TARGET_PATH)
        DEFAULT_KEY_TARGET_PATH = '/etc/pki/tls/icm/private'.freeze
      end
      unless const_defined?(:NODE_CACERT_FILE)
        NODE_CACERT_FILE = 'ca_bundle.pem'.freeze
      end
      unless const_defined?(:NODE_CERT_FILE)
        NODE_CERT_FILE = 'controller_crt.pem'.freeze
      end
      unless const_defined?(:NODE_KEY_FILE)
        NODE_KEY_FILE = 'controller_key.pem'.freeze
      end
      unless const_defined?(:DEFAULT_SSL_VAULT_NAME)
        DEFAULT_SSL_VAULT_NAME = 'icm_ssl_vault'.freeze
      end
      unless const_defined?(:DEFAULT_SSL_VAULT_ADMINS)
        DEFAULT_SSL_VAULT_ADMINS = 'os-software-management'.freeze
      end
      unless const_defined?(:MAX_WAIT_FOR_NODES_IN_SECONDS)
        MAX_WAIT_FOR_NODES_IN_SECONDS = 300
      end
      unless const_defined?(:DEFAULT_RUN_SEQUENTIALLY)
        DEFAULT_RUN_SEQUENTIALLY = false
      end

      # Node number limits
      MIN_HA_CONTROLLERS = 3.freeze unless const_defined?(:MIN_HA_CONTROLLERS)
      MAX_HA_CONTROLLERS = 10.freeze unless const_defined?(:MAX_HA_CONTROLLERS)
      MAX_CONTROLLERS = 1.freeze unless const_defined?(:MAX_CONTROLLERS)
      MAX_PARALLEL_NODES = 10.freeze unless const_defined?(:MAX_PARALLEL_NODES)

      # Deploy options
      unless const_defined?(:DEFAULT_DEPLOY_OPTIONS)
        DEFAULT_DEPLOY_OPTIONS = {
          bootstrap: true,
          set_run_list: true,
          deploy: true,
          quit_immediately_on_error: false,
          concurrency: MAX_PARALLEL_NODES
        }
      end
    end
  end
end
