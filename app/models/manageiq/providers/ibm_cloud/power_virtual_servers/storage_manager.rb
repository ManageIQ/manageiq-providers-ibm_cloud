class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager < ManageIQ::Providers::StorageManager
  require_nested :CloudVolume
  require_nested :Refresher

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin
  include ManageIQ::Providers::StorageManager::BlockMixin

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
           :key_pairs,
           :to        => :parent_manager,
           :allow_nil => true

  def self.ems_type
    @ems_type ||= "ibm_cloud_storage".freeze
  end

  def self.description
    @description ||= "IBM Cloud Storage".freeze
  end

  def self.hostname_required?
    false
  end
end
