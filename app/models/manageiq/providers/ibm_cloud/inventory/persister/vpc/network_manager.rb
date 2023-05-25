class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC::NetworkManager < ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC
  def storage_manager
    manager.parent_manager.storage_manager
  end
end
