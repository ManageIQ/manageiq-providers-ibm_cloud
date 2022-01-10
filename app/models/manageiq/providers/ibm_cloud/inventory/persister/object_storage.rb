class ManageIQ::Providers::IbmCloud::Inventory::Persister::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Persister
  require_nested :StorageManager

  def initialize_inventory_collections
    add_collection(storage, :cloud_object_store_objects) do |builder|
      builder.add_properties(:model_class => ManageIQ::Providers::IbmCloud::ObjectStorage::StorageManager::CloudObjectStoreObject)
    end
    add_collection(storage, :cloud_object_store_containers) do |builder|
      builder.add_properties(:model_class => ManageIQ::Providers::IbmCloud::ObjectStorage::StorageManager::CloudObjectStoreContainer)
    end
  end
end
