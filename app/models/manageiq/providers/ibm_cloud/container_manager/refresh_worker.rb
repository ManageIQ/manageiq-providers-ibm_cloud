class ManageIQ::Providers::IbmCloud::ContainerManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  require_nested :Runner
  require_nested :WatchThread

  def self.settings_name
    :ems_refresh_worker_ibm_cloud_iks
  end
end
