class ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner

  def self.all_valid_ems_in_zone
    super.select do |ems|
      ems.authentication_key("events").present? && ems.authentication_status_ok?(:events)
    end
  end
end
