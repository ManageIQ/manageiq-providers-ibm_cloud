class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager < ManageIQ::Providers::StorageManager
  require_nested :CloudVolume
  require_nested :CloudVolumeType
  require_nested :Refresher

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin
  include ManageIQ::Providers::StorageManager::BlockMixin

  delegate :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :authentications,
           :authentication_for_summary,
           :connect,
           :verify_credentials,
           :with_provider_connection,
           :address,
           :ip_address,
           :hostname,
           :default_endpoint,
           :endpoints,
           :key_pairs,
           :snapshots,
           :to        => :parent_manager,
           :allow_nil => true

  virtual_delegate :cloud_tenants, :to => :parent_manager, :allow_nil => true
  virtual_delegate :volume_availability_zones, :to => :parent_manager, :allow_nil => true

  supports :cloud_volume
  supports :cloud_volume_create

  def image_name
    "ibm_power_vs"
  end

  def self.ems_type
    @ems_type ||= "ibm_cloud_power_virtual_servers_storage".freeze
  end

  def self.description
    @description ||= "IBM Power Systems Virtual Servers Storage".freeze
  end

  def self.hostname_required?
    false
  end
end
