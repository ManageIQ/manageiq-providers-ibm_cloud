class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.settings_name
    :ems_refresh_worker_ibm_cloud_power_virtual_servers
  end
end
