class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :CloudManager

  def cloud_manager
    manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  end

  def self.provider_module
    "ManageIQ::Providers::IbmCloud::VPC"
  end

  def initialize_inventory_collections
    add_cloud_collection(:vms) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    end
    add_cloud_collection(:hardwares)
    add_cloud_collection(:availability_zones)
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:auth_key_pairs) do |builder|
      builder.add_default_values(
        :resource_id   => ->(persister) { persister.cloud_manager.id },
        :resource_type => ->(persister) { persister.cloud_manager.class.base_class }
      )
    end
    add_cloud_collection(:miq_templates) do |builder|
      builder.add_properties(:model_class => ::ManageIQ::Providers::IbmCloud::VPC::CloudManager::Template)
      builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    end
  end

  def add_cloud_collection(name)
    add_collection(cloud, name) do |builder|
      builder.add_properties(:parent => cloud_manager)
      yield builder if block_given?
    end
  end
end
