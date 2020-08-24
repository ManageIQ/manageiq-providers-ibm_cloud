class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "ibm_cloud_power_virtual_servers"

  def self.settings_name
    :ems_metrics_collector_worker_ibm_cloud_power_virtual_servers
  end

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for ManageIQ::Providers::IbmCloud::PowerVirtualServers"
  end
end
