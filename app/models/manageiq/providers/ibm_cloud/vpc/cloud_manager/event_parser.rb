module ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type => event["action"],
      :source     => "IBMCloud-VPC",
      :username   => event.dig("initiator", "name"),
      :ems_id     => ems_id,
      :ems_ref    => event["_id"],
      :timestamp  => event["eventTime"],
      :full_data  => event
    }

    case event_hash[:event_type]
    when /^is\.instance/
      parse_vm_event!(event, event_hash)
    end

    event_hash
  end

  def self.parse_vm_event!(event, event_hash)
    vm_ref = event.dig('target', 'id').match(/::instance:(?<instance_id>\S+)$/)
    return if vm_ref.nil?

    event_hash[:vm_uid_ems] = vm_ref.named_captures["instance_id"]
    event_hash[:vm_ems_ref] = vm_ref.named_captures["instance_id"]
  end
end
