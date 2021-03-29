class ManageIQ::Providers::IbmCloud::VPC::StorageManager < ManageIQ::Providers::StorageManager
  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin
  include ManageIQ::Providers::StorageManager::BlockMixin

  require_nested :CloudVolumeType

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

  def self.ems_type
    @ems_type ||= "ibm_cloud_vpc_storage".freeze
  end

  def self.description
    @description ||= "IBM Cloud Servers Storage".freeze
  end

  def self.hostname_required?
    false
  end
end
