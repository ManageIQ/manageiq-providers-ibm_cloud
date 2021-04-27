class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def self.provider_module
    "ManageIQ::Providers::IbmCloud::VPC"
  end

  def initialize_inventory_collections
    initialize_tag_mapper
    initialize_cloud_inventory_collections
    initialize_network_inventory_collections
    initialize_storage_inventory_collections
  end

  def initialize_cloud_inventory_collections
    add_cloud_collection(:vms)
    add_cloud_collection(:hardwares)
    add_cloud_collection(:availability_zones)
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:disks)
    add_cloud_collection(:auth_key_pairs)
    add_cloud_collection(:miq_templates)
    add_cloud_collection(:flavors)
    add_cloud_collection(:vm_and_miq_template_ancestry)
    add_cloud_collection(:networks)
    add_cloud_collection(:vm_and_template_labels)
    add_cloud_collection(:vm_and_template_taggings)

    # Define resource_groups method on CloudManager
    add_cloud_collection(:resource_groups, {}, {:auto_inventory_attributes => false}) { |builder| add_resource_group(builder) }
  end

  def initialize_network_inventory_collections
    add_network_collection(:security_groups)
    add_network_collection(:cloud_networks)
    add_network_collection(:cloud_subnets)
    add_network_collection(:floating_ips)
    add_network_collection(:network_ports)
    add_network_collection(:cloud_subnet_network_ports)
  end

  def initialize_storage_inventory_collections
    add_storage_collection(:cloud_volumes)
    add_storage_collection(:cloud_volume_types)
  end

  # Automatically add the local model class and id of ems to the database record.
  # @return [void]
  def add_resource_group(builder)
    builder.add_properties(:model_class => ::ManageIQ::Providers::IbmCloud::VPC::ResourceGroup)
    builder.add_default_values(:ems_id => manager.id)
  end
end
