class ManageIQ::Providers::IbmCloud::VPC::NetworkManager < ManageIQ::Providers::NetworkManager
  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin

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
           :provider_region,
           :refresh,
           :refresh_ems,
           :to        => :parent_manager,
           :allow_nil => true

  class << self
    delegate :refresh_ems, :to => ManageIQ::Providers::IbmCloud::VPC::CloudManager
  end

  def image_name
    "ibm_cloud"
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
    @ems_type ||= "ibm_cloud_vpc_network".freeze
  end

  def self.description
    @description ||= "IBM Cloud VPC Network".freeze
  end

  def create_cloud_network(options)
    CloudNetwork.raw_create_cloud_network(self, options)
  end

  def create_cloud_subnet(options)
    CloudSubnet.raw_create_cloud_subnet(self, options)
  end
end
