class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def connection
    @connection ||= manager.connect
  end

  def vms
    connection.instances.all
  end

  def vm_key_pairs(vm_id)
    connection.request(:get_instance_initialization, :id => vm_id) || {}
  end

  def flavors
    connection.request(:list_instance_profiles)[:profiles]
  end

  def images
    @images ||= connection.collection(:list_images).to_a
  end

  def images_by_id
    @images_by_id ||= images.index_by { |img| img[:id] }
  end

  def image(image_id)
    connection.request(:get_image, :id => image_id)
  end

  def keys
    connection.request(:list_keys)[:keys]
  end

  def availability_zones
    connection.request(:list_region_zones, :region_name => manager.provider_region)[:zones]
  end

  def security_groups
    connection.collection(:list_security_groups)
  end

  def cloud_networks
    connection.collection(:list_vpcs)
  end

  def cloud_subnets
    connection.collection(:list_subnets)
  end

  def floating_ips
    connection.collection(:list_floating_ips)
  end

  def volumes
    connection.collection(:list_volumes)
  end

  def volume(volume_id)
    connection.request(:get_volume, :id => volume_id)
  end

  # Fetch volume profiles from VPC. Each item has following keys :name, :family, :href.
  # @return [Array<Hash<Symbol, String>>]
  def volume_profiles
    connection.collection(:list_volume_profiles)
  end

  def tags_by_crn(crn)
    connection.cloudtools.tagging.collection(:list_tags, :attached_to => crn, :providers => ["ghost"]).to_a
  end
end
