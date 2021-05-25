class ManageIQ::Providers::IbmCloud::Inventory::Persister::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :StorageManager

  def initialize_inventory_collections
    add_collection(storage, :cloud_object_store_objects)
    add_collection(storage, :cloud_object_store_containers)
  end
end
