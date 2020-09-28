class ManageIQ::Providers::IbmCloud::VPC::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :SecurityGroup
  require_nested :CloudNetwork
  require_nested :FloatingIp

  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin

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

  def image_name
    "ibm"
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
end
