class ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventTargetParser
  attr_reader :ems_event

  def initialize(ems_event)
    @ems_event = ems_event
  end

  def parse
    parse_ems_event_targets(ems_event)
  end

  def parse_ems_event_targets(event)
    target_collection = InventoryRefresh::TargetCollection.new(
      :manager => event.ext_management_system,
      :event   => event
    )

    case event[:event_type]
    when /^is\.instance/
      target_collection.add_target(
        :association => :vms,
        :manager_ref => {:ems_ref => event[:vm_ems_ref]}
      )
    end

    target_collection.targets
  end
end
