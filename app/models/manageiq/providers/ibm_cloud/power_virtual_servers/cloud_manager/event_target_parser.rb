class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventTargetParser
  attr_reader :ems_event

  def initialize(ems_event)
    @ems_event = ems_event
  end

  def parse
    targets = []

    case ems_event[:event_type]
    when /^image\.delete/
      targets << InventoryRefresh::Target.new(
        :association => :miq_templates,
        :manager_ref => {:ems_ref => ems_event.vm_ems_ref},
        :manager_id  => ems_event.ext_management_system.id,
        :event_id    => ems_event.id
      )
    when /^image/
      if ems_event[:message].include?("successfully imported into image catalog")
        targets << ems_event.ext_management_system
      end
    when /^network/
      targets << InventoryRefresh::Target.new(
        :association => :cloud_subnets,
        :manager_ref => {:ems_ref => ems_event[:vm_ems_ref]},
        :manager_id  => ems_event.ext_management_system.network_manager.id,
        :event_id    => ems_event.id
      )
    when /^pvm-instance\.create/
      targets << ems_event.ext_management_system
    when /^pvm-instance\.update/
      targets << ems_event.ext_management_system
    when /^pvm-instance/
      targets << InventoryRefresh::Target.new(
        :association => :vms,
        :manager_ref => {:ems_ref => ems_event[:vm_ems_ref]},
        :manager_id  => ems_event.ext_management_system.id,
        :event_id    => ems_event.id
      )
    when /^volume/
      targets << ems_event.ext_management_system.storage_manager
    end

    targets
  end
end
