module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type => "#{event[:resource]}.#{event[:action]}",
      :source     => "IBMCloud-PowerVS",
      :ems_id     => ems_id,
      :ems_ref    => event[:eventID],
      :timestamp  => event[:time],
      :full_data  => event,
      :username   => event.dig(:user, :email)
    }

    _log.debug("event_hash=#{event_hash}")
    case event_hash[:event_type]
    when /^pvm-instance/
      parse_vm_event!(event, event_hash)
    end

    event_hash
  end

  def self.parse_vm_event!(event, event_hash)
    if ['update', 'create'].include?(event['type'])
      event_hash
    else
      pvm_instance_name = event[:message].split('\'')[1]

      # PowerVS VMs and Templates are required to have unique names within
      # service instance.
      vm = VmOrTemplate.find_by(
        :ems_id => event_hash[:ems_id],
        :name   => pvm_instance_name
      )

      return if vm.nil?

      event_hash[:vm_uid_ems] = vm.uid_ems
      event_hash[:vm_ems_ref] = vm.ems_ref
      event_hash[:vm_name]    = vm.name
    end
  end
end
