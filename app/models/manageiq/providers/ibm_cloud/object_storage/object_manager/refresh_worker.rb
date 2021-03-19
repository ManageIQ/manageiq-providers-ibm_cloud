class ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.settings_name
    :ems_refresh_worker_ibm_cloud_object_storage
  end
end
