class ManageIQ::Providers::IbmCloud::ContainerManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  def self.settings_name
    :ems_refresh_worker_ibm_cloud_iks
  end
end
