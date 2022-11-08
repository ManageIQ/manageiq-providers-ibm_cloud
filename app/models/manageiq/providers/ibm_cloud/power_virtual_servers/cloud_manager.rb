class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :AvailabilityZone
  require_nested :EventCatcher
  require_nested :Flavor
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :PlacementGroup
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :SAPProfile
  require_nested :Snapshot
  require_nested :Template
  require_nested :Vm
  require_nested :ResourcePool

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

  has_many :import_auths,
           :foreign_key => :resource_id,
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImageImportAuth",
           :autosave    => true,
           :dependent   => :destroy

  has_many :ssh_auths,
           :foreign_key => :resource_id,
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::SshPkeyAuth",
           :autosave    => true,
           :dependent   => :destroy

  has_many :system_types,
           :foreign_key => :ems_id,
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType"

  has_many :snapshots, :through => :vms_and_templates

  before_create :ensure_managers
  before_update :ensure_managers_zone

  supports :catalog
  supports :create
  supports :native_console
  supports :provisioning
  supports_not :volume_availability_zones

  def console_url
    "https://cloud.ibm.com/services/power-iaas/#{CGI.escape(pcloud_crn.values.join(":"))}"
  end

  def image_name
    "ibm_power_vs"
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

  def create_import_auth(key, iv, creds)
    import_auths.create!(:auth_key => key, :auth_key_password => iv, :password => creds).id
  end

  def create_ssh_pkey_auth(pkey, unlock)
    ssh_auths.create!(:auth_key => pkey, :auth_key_password => unlock).id
  end

  def remove_import_auth(id)
    import_auths.destroy(id)
  end

  def remove_ssh_auth(id)
    ssh_auths.destroy(id)
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

  def self.catalog_types
    {"IbmCloud::PowerVirtualServers" => N_("IBM PowerVS")}
  end
end
