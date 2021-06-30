class ManageIQ::Providers::IbmCloud::VPC::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :Flavor
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :Template
  require_nested :Vm
  require_nested :LoggingMixin

  supports :provisioning

  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin
  delegate :cloud_volumes, :to => :storage_manager
  delegate :cloud_volume_types, :to => :storage_manager

  has_one :storage_manager,
          :foreign_key => :parent_ems_id,
          :class_name  => "ManageIQ::Providers::IbmCloud::VPC::StorageManager",
          :autosave    => true,
          :dependent   => :destroy,
          :inverse_of  => :parent_manager

  before_create :ensure_managers
  before_update :ensure_managers_zone

  supports :label_mapping

  def ensure_managers
    ensure_network_manager
    ensure_storage_manager
    ensure_managers_zone
  end

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager') unless network_manager
    network_manager.name = "#{name} Network Manager"
  end

  def ensure_storage_manager
    build_storage_manager(:type => 'ManageIQ::Providers::IbmCloud::VPC::StorageManager') unless storage_manager
    storage_manager.name = "#{name} Block Storage Manager"
  end

  def ensure_managers_zone
    network_manager.zone_id = zone_id if network_manager
    storage_manager.zone_id = zone_id if storage_manager
  end

  def image_name
    'ibm'
  end

  def self.hostname_required?
    false
  end

  def self.ems_type
    @ems_type ||= 'ibm_vpc'.freeze
  end

  def self.description
    @description ||= 'IBM Cloud VPC'.freeze
  end

  def self.provider_region_options
    ManageIQ::Providers::IbmCloud::VPC::Regions
      .all
      .sort_by { |r| r[:description].downcase }
      .map do |r|
        {
          :label => r[:description],
          :value => r[:name]
        }
      end
  end

  LABEL_MAPPING_ENTITIES = {
    "VmIBM"    => "ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm",
    "ImageIBM" => "ManageIQ::Providers::IbmCloud::VPC::CloudManager::Template"
  }.freeze

  def self.entities_for_label_mapping
    LABEL_MAPPING_ENTITIES
  end

  def self.label_mapping_prefix
    "ibm"
  end
end
