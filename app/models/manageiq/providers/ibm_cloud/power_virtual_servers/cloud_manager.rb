class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :Template
  require_nested :Vm
  require_nested :SAPProfile

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin

  delegate :cloud_volumes,
           :cloud_volume_types,
           :to        => :storage_manager,
           :allow_nil => true

  has_one :storage_manager,
          :foreign_key => :parent_ems_id,
          :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager",
          :autosave    => true,
          :inverse_of  => :parent_manager,
          :dependent   => :destroy

  has_many :system_types,
           :foreign_key => :ems_id,
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType"

  before_create :ensure_managers
  before_update :ensure_managers_zone

  supports :auth_key_pair_create
  supports :provisioning
  supports_not :volume_availability_zones

  def image_name
    "ibm"
  end

  def ensure_managers
    ensure_network_manager
    ensure_storage_manager
    ensure_managers_zone
  end

  def ensure_managers_zone
    network_manager.zone_id = zone_id if network_manager
    storage_manager.zone_id = zone_id if storage_manager
  end

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager') unless network_manager
    network_manager.name = "#{name} Network Manager"
  end

  def ensure_storage_manager
    build_storage_manager unless storage_manager
    storage_manager.name = "#{name} Block Storage Manager"
  end

  def self.hostname_required?
    # TODO: ExtManagementSystem is validating this
    false
  end

  def self.ems_type
    @ems_type ||= "ibm_cloud_power_virtual_servers".freeze
  end

  def self.description
    @description ||= "IBM Power Systems Virtual Servers".freeze
  end
end
