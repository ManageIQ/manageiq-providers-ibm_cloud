module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventParser
  def self.event_to_hash(event, ems_id)
    ems = ExtManagementSystem.find(ems_id)
    event_hash = {
      :event_type => "#{event[:resource]}.#{event[:action]}",
      :source     => "IBMCloud-PowerVS",
      :ems_id     => ems_id,
      :ems_ref    => event[:eventID],
      :timestamp  => event[:time],
      :full_data  => event,
      :username   => event[:user][:email]
    }

    _log.debug("event_hash=#{event_hash}")
    case event_hash[:event_type]
    when /^pvm-instance/
      parse_vm_event!(event, event_hash)
    end

    event_hash
  end

  def self.parse_vm_event!(event, event_hash)
    pvm_instance_name = event[:message].split('\'')[1]
    vm = ems.vms.find_by(:name => pvm_instance_name)
    return if vm.nil?

    event_hash[:vm_uid_ems] = vm.uid_ems
    event_hash[:vm_ems_ref] = vm.ems_ref
    event_hash[:vm_name] = vm.name
  end
end