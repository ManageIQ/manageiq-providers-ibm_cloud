class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC::StorageManager < ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC
  def network_manager
    manager.parent_manager.network_manager
  end
end
