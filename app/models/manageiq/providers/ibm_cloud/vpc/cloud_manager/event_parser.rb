module ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type => event["action"],
      :source     => "IBM_CLOUD_VPC",
      :ems_id     => ems_id,
      :ems_ref    => event["_id"],
      :timestamp  => event["eventTime"],
      :full_data  => event
    }

    case event_hash[:event_type]
    when 'is.instance.instance.create'
      parse_vm_event!(event, event_hash)
    end

    event_hash
  end

  def self.parse_vm_event!(event, event_hash)
    return if event['responseData'].nil?

    event_hash[:vm_uid_ems] = event.dig('responseData', 'id')
    event_hash[:vm_ems_ref] = event.dig('responseData', 'id')
    event_hash[:vm_name]    = event.dig('responseData', 'name')
  end
end
