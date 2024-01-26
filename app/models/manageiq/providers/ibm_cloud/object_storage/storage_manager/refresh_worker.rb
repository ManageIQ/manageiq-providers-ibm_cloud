class ManageIQ::Providers::IbmCloud::ObjectStorage::StorageManager::RefreshWorker < MiqEmsRefreshWorker
  def self.settings_name
    :ems_refresh_worker_ibm_cloud_object_storage
  end
end
