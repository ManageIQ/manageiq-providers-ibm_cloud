module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type => "#{event[:resource]}.#{event[:action]}",
      :source     => "IBMCloud-PowerVS",
      :ems_id     => ems_id,
      :ems_ref    => event[:eventID],
      :timestamp  => event[:time],
      :full_data  => event
    }

    case event_hash[:event_type]
    when /^pvm-instance/
      parse_vm_event!(event, event_hash)
    end

    event_hash
  end

  def self.parse_vm_event!(event, event_hash)
    return if event[:metadata][:pvm_instance_id].nil?

    # The uid_ems/ems_ref should match the attributes that you set in the inventory
    # parser since they will be used to lookup the VM object by the MiqEventHandler
    event_hash[:vm_uid_ems] = "8283634d-5215-4706-a0d8-9a8f8e9dfc01"  # TODO: Get real PVM ID
    event_hash[:vm_ems_ref] = "8283634d-5215-4706-a0d8-9a8f8e9dfc01"  # TODO: Get real PVM ID
  end
end
