class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager

  def connection
    @connection ||= manager.connect
  end

  def vms
    connection.instances.all
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
end
