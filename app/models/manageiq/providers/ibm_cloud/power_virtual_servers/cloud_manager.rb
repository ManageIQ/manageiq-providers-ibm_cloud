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
          :autosave    => true,
          :dependent   => :destroy,
          :inverse_of  => :parent_manager

  has_one :storage_manager,
          :foreign_key => :parent_ems_id,
          :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager",
          :autosave    => true,
          :dependent   => :destroy,
          :inverse_of  => :parent_manager

  before_create :ensure_managers

  belongs_to :provider,
             :class_name => "ManageIQ::Providers::IbmCloud::Provider",
             :inverse_of => :power_virtual_servers_cloud_managers,
             :dependent  => :destroy,
             :autosave   => true

  delegate :name=,
           :zone,
           :zone=,
           :zone_id,
           :zone_id=,
           :authentications,
           :authentications=,
           :to => :provider

  supports :provisioning

  def image_name
    "ibm"
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

  def self.create_from_params(params, endpoints, authentications)
    new(params).tap do |ems|
      endpoints.each { |endpoint| ems.assign_nested_endpoint(endpoint) }
      authentications.each { |authentication| ems.assign_nested_authentication(authentication) }

      ems.provider.save!
      ems.save!
    end
  end

  def edit_with_params(params, endpoints, authentications)
    tap do |ems|
      transaction do
        # Remove endpoints/attributes that are not arriving in the arguments above
        ems.endpoints.where.not(:role => nil).where.not(:role => endpoints.map { |ep| ep['role'] }).delete_all
        ems.authentications.where.not(:authtype => nil).where.not(:authtype => authentications.map { |au| au['authtype'] }).delete_all

        ems.assign_attributes(params)
        ems.endpoints = endpoints.map(&method(:assign_nested_endpoint))
        ems.authentications = authentications.map(&method(:assign_nested_authentication))

        ems.provider.save!
        ems.save!
      end
    end
  end

  def ensure_managers
    build_network_manager unless network_manager
    build_storage_manager unless storage_manager
  end

  def provider
    super || build_provider
  end

  def name
    "#{provider.name} Power Virtual Servers"
  end
end
