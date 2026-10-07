class ManageIQ::Providers::IbmCloud::ContainerManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  include ManageIQ::Providers::Kubernetes::ContainerManager::EventCatcherMixin

  private

  def worker_cmdline
    ManageIQ::Providers::IbmCloud::Engine.root.join("workers/manageiq/providers/ibm_cloud/container_manager/event_catcher/worker").to_s
  end
end
