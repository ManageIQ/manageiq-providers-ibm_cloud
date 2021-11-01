class ManageIQ::Providers::IbmCloud::VPC::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "ibm_cloud_vpc"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for IBM Cloud VPC"
  end
end
