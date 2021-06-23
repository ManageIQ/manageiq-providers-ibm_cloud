class ManageIQ::Providers::IbmCloud::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :ObjectStorage
  require_nested :PowerVirtualServers
  require_nested :VPC
end
