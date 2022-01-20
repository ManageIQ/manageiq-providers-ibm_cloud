class ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture < ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCapture
  require_nested :PrometheusCaptureContext

  def prometheus_capture_context(target, start_time, end_time)
    ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture::PrometheusCaptureContext.new(target, start_time, end_time, INTERVAL)
  end
end
