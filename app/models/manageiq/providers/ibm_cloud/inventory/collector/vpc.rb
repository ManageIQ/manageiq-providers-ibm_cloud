class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  
  def connection
    manager.connect
  end

  def vms
    connection.instances.all
  end

end