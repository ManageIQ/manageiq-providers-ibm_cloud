class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager < ManageIQ::Providers::NetworkManager
  supports :create

  require_nested :Refresher
  require_nested :CloudNetwork
  require_nested :CloudSubnet
  require_nested :NetworkPort

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin

  delegate :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :authentications,
           :authentication_for_summary,
           :zone,
           :connect,
           :verify_credentials,
           :with_provider_connection,
           :address,
           :ip_address,
           :hostname,
           :default_endpoint,
           :endpoints,
           :to        => :parent_manager,
           :allow_nil => true

  def self.validate_authentication_args(params)
    # return args to be used in raw_connect
    [params[:default_userid], ManageIQ::Password.encrypt(params[:default_password])]
  end

  def self.hostname_required?
    # TODO: ExtManagementSystem is validating this
    false
  end

  def self.ems_type
    @ems_type ||= "ibm_cloud_networks".freeze
  end

  def self.description
    @description ||= "IBM Cloud Networks".freeze
  end

  def create_cloud_subnet(options)
    raw_create_cloud_subnet(self, options)
  end

  def create_cloud_subnet_queue(userid, options = {})
    task_opts = {
      :action => "creating Cloud Subnet for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'create_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => [options]
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_create_cloud_subnet(ext_management_system, options)
    ext_management_system.with_provider_connection({:target => 'PowerIaas'}) do |power_iaas|
      type ||= 'vlan'

      subnet = {
        :type       => type,
        :name       => options[:name],
        :cidr       => options[:cidr],
        :gateway    => options[:gateway_ip],
        :dnsservers => options[:dns_nameservers],
      }

      power_iaas.create_network(subnet)
    end
  end
end
