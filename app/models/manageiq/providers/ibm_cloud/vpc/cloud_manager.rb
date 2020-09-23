class ManageIQ::Providers::IbmCloud::VPC::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :Refresher
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin

  before_create :ensure_managers
  before_update :ensure_managers_zone

  def ensure_managers
    ensure_network_manager
    ensure_managers_zone
  end

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager') unless network_manager
    network_manager.name = "Network-Manager of '#{name}'"
  end

  def ensure_managers_zone
    network_manager.zone_id = zone_id if network_manager
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
    @description ||= 'IBM Virtual Private Cloud'.freeze
  end
end
