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
    # add_cloud_collection(:vms) do |builder|
    #   builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    # end
    # add_collection(cloud, :vms) do |builder|
    #   builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    #   builder.add_properties(:parent => cloud_manager)
    #   yield builder if block_given?
    # end
    # add_cloud_collection(:vms) do |builder|
    #   builder.add_default_values(:ems_id => ->(persister) { persister.cloud_manager.id })
    # end
  end

  # def add_cloud_collection(name)
  #   add_collection(cloud, name) do |builder|
  #     builder.add_properties(:parent => cloud_manager)
  #     yield builder if block_given?
  #   end
  # end

end