class ManageIQ::Providers::IbmCloud::VPC::CloudManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.settings_name
    :ems_refresh_worker_ibm_cloud_vpc
  end
end
