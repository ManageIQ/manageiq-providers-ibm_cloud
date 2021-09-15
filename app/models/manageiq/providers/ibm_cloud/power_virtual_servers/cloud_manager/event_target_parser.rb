class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventTargetParser
  attr_reader :ems_event

  def initialize(ems_event)
    @ems_event = ems_event
  end

  def parse
    target_collection = InventoryRefresh::TargetCollection.new(
      :manager => ems_event.ext_management_system,
      :event   => ems_event
    )

    case ems_event[:event_type]
    when /^pvm-instance/
      target_collection.add_target(
        :association => :vms,
        :manager_ref => {:ems_ref => ems_event[:vm_ems_ref]}
      )
    end

    target_collection.targets
  end
end
