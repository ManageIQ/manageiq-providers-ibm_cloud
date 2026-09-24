class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager < ManageIQ::Providers::NetworkManager
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
           :refresh,
           :refresh_ems,
           :to        => :parent_manager,
           :allow_nil => true

  class << self
    delegate :refresh_ems, :to => ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager
  end

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
    CloudSubnet.raw_create_cloud_subnet(self, options)
  end
end