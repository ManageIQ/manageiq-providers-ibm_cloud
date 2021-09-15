class ManageIQ::Providers::IbmCloud::Inventory::Persister::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Persister::ContainerManager
  require_nested :WatchNotice
end
