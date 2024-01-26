class ManageIQ::Providers::IbmCloud::ContainerManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  def self.settings_name
    :event_catcher_ibm_cloud_iks
  end
end
