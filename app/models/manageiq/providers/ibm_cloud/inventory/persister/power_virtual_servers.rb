class ManageIQ::Providers::IbmCloud::Inventory::Persister::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
    initialize_network_inventory_collections
    initialize_storage_inventory_collections
  end

  def self.provider_module
    "ManageIQ::Providers::IbmCloud::PowerVirtualServers"
  end

  private

  def initialize_cloud_inventory_collections
    add_cloud_collection(:availability_zones)
    add_cloud_collection(:flavors)
    add_cloud_collection(:vms)
    add_cloud_collection(:hardwares)
    add_cloud_collection(:disks)
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:placement_groups)
    add_cloud_collection(:auth_key_pairs)
    add_cloud_collection(:miq_templates)
    add_cloud_collection(:snapshots)
    add_cloud_collection(:ext_management_system)
    add_cloud_collection(:resource_pools)
    add_cloud_collection(:vm_resource_pools)
    add_advanced_settings
  end

  def initialize_network_inventory_collections
    add_network_collection(:cloud_networks)
    add_network_collection(:cloud_subnets)
    add_network_collection(:network_ports)
    add_network_collection(:cloud_subnet_network_ports)
    add_network_collection(:load_balancers)
  end

  def initialize_storage_inventory_collections
    add_storage_collection(:cloud_volumes)
    add_storage_collection(:cloud_volume_types)
  end

  def add_advanced_settings
    add_collection(cloud, :vms_and_templates_advanced_settings) do |builder|
      builder.add_properties(
        :manager_ref                  => %i[resource name],
        :model_class                  => ::AdvancedSetting,
        :parent_inventory_collections => %i[vms]
      )
    end
  end
end
