class ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "iks"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for IKS"
  end

  def self.all_ems_in_zone
    super.select do |ems|
      ems.supports?(:metrics).tap do |supported|
        _log.info("Skipping [#{ems.name}] since it has no metrics endpoint") unless supported
      end
    end
  end

  def self.settings_name
    :ems_metrics_collector_worker_ibm_cloud_iks
  end
end
