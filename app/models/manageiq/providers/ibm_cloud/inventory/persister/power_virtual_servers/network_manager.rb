class ManageIQ::Providers::IbmCloud::Inventory::Persister::PowerVirtualServers::NetworkManager < ManageIQ::Providers::IbmCloud::Inventory::Persister::PowerVirtualServers
  def storage_manager
    manager.parent_manager.storage_manager
  end
end
