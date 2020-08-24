class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner

  def self.settings_name
    :event_catcher_ibm_cloud_power_virtual_servers
  end
end
