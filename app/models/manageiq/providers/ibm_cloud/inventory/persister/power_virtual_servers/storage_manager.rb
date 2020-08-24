class ManageIQ::Providers::IbmCloud::Inventory::Persister::PowerVirtualServers::StorageManager < ManageIQ::Providers::IbmCloud::Inventory::Persister::PowerVirtualServers
  def network_manager
    manager.parent_manager.network_manager
  end
end
