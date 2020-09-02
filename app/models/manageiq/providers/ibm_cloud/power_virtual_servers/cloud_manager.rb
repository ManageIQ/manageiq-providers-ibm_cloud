class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin

  has_one :network_manager,
          :foreign_key => :parent_ems_id,
          :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager",
          :autosave    => true
          :dependent   => :destroy

  has_one :storage_manager,
          :foreign_key => :parent_ems_id,
          :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager",
          :autosave    => true,
          :dependent   => :destroy

  before_create :ensure_managers

  supports :provisioning

  def image_name
    "ibm"
  end

  def ensure_managers
    ensure_network_manager
    ensure_storage_manager
  end

  def ensure_network_manager
    build_network_manager unless network_manager
  end

  def ensure_storage_manager
    build_storage_manager unless storage_manager
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
