class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager

  def connection
    @connection ||= manager.connect
  end

  def vms
    connection.instances.all
  end

  def vm_key_pairs(vm_id)
    connection.instances.instance(vm_id)&.initialization || {}
  end

  def flavors
    connection.instance_profiles.all
  end

  def images
    connection.images.all
  end

  def image(image_id)
    connection.images.instance(image_id)&.details
  end

  def keys
    connection.keys.all
  end

  def availability_zones
    connection.regions.instance(manager.provider_region).zones.all
  end

  def security_groups
    connection.security_groups.all
  end

  def cloud_networks
    connection.vpcs.all
  end

  def cloud_subnets
    connection.subnets.all
  end
end
