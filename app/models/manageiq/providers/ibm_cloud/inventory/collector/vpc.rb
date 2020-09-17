class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager

  def connection
    manager.connect
  end

  def vms
    connection.instances.all
  end

  def images
    connection.images.all
  end

  def image(image_id)
    connection.images.instance(image_id).details
  end
end
