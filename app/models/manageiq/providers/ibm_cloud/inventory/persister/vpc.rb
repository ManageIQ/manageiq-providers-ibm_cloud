class ManageIQ::Providers::IbmCloud::Inventory::Persister::VPC < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :CloudManager
  
  # def cloud_manager
  #   manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  # end

  def self.provider_module
    "ManageIQ::Providers::IbmCloud::VPC"
  end

  def initialize_inventory_collections
    add_collection(cloud, :vms)
  end

end
