class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def cloud_manager
    manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  end

  def network_manager
    manager.kind_of?(EmsNetwork) ? manager : manager.network_manager
  end

  def storage_manager
    manager.kind_of?(EmsStorage) ? manager : manager.storage_manager
  end

  def self.provider_module
    "ManageIQ::Providers::IbmCloud::VPC"
  end

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
    initialize_network_inventory_collections
    initialize_storage_inventory_collections
  end

  def initialize_cloud_inventory_collections
    add_cloud_collection(:vms) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    end
    add_cloud_collection(:hardwares)
    add_cloud_collection(:availability_zones)
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:disks)
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
    add_cloud_collection(:flavors)
    add_cloud_collection(:vm_and_miq_template_ancestry)
    add_cloud_collection(:networks)
  end

  def initialize_network_inventory_collections
    add_network_collection(:security_groups) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.network_manager.id })
    end
    add_network_collection(:cloud_networks) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.network_manager.id })
    end
    add_network_collection(:cloud_subnets) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.network_manager.id })
    end
    add_network_collection(:floating_ips) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.network_manager.id })
    end
    add_network_collection(:network_ports) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.network_manager.id })
    end
    add_network_collection(:cloud_subnet_network_ports)
  end

  def initialize_storage_inventory_collections
    add_storage_collection(:cloud_volumes) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.storage_manager.id })
    end
  end

  def add_storage_collection(name)
    add_collection(storage, name) do |builder|
      builder.add_properties(:parent => storage_manager)
      yield builder if block_given?
    end
  end

  def add_network_collection(name)
    add_collection(network, name) do |builder|
      builder.add_properties(:parent => network_manager)
      yield builder if block_given?
    end
  end

  def add_cloud_collection(name)
    add_collection(cloud, name) do |builder|
      builder.add_properties(:parent => cloud_manager)
      yield builder if block_given?
    end
  end
end
