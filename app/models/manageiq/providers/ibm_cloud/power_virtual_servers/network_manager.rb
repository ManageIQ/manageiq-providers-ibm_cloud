class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :Refresher
  require_nested :CloudNetwork
  require_nested :CloudSubnet
  require_nested :LoadBalancer
  require_nested :NetworkPort
  require_nested :NetworkRouter
  require_nested :SecurityGroup

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin

  supports :cloud_subnet_create

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
           :snapshots,
           :to        => :parent_manager,
           :allow_nil => true

  def image_name
    "ibm_power_vs"
  end

  def self.validate_authentication_args(params)
    # return args to be used in raw_connect
    [params[:default_userid], ManageIQ::Password.encrypt(params[:default_password])]
  end

  def self.hostname_required?
    # TODO: ExtManagementSystem is validating this
    false
  end

  def self.ems_type
    @ems_type ||= "ibm_cloud_power_virtual_servers_network".freeze
  end

  def self.description
    @description ||= "IBM Power Systems Virtual Servers Network".freeze
  end

  def create_cloud_subnet(options)
    raw_create_cloud_subnet(self, options)
  end

  def self.raw_create_cloud_subnet(ext_management_system, options)
    cloud_instance_id = ext_management_system.parent_manager.uid_ems

    ext_management_system.with_provider_connection(:service => 'PCloudNetworksApi') do |api|
      network = IbmCloudPower::NetworkCreate.new(
        :type        => options[:type] || 'pub-vlan',
        :name        => options[:name],
        :cidr        => options[:cidr],
        :gateway     => options[:gateway_ip],
        :dns_servers => options[:dns_nameservers]
      )

      api.pcloud_networks_post(cloud_instance_id, network)
    end
  end
end
