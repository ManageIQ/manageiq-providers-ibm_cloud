class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC::TargetCollection < ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC
  def initialize(_manager, _target)
    super
    
    parse_targets!
  end

  def images
    []
  end
  
  def instances
    @instances ||= begin
      references(:vms).map do |ems_ref|
        compute_client.get_instance(ems_ref)
      end
    end
  end

  def instance_types
    []
  end

  private

  def parse_targets!
    # `target` here is an `InventoryRefresh::TargetCollection`.  This contains two types of targets,
    # `InventoryRefresh::Target` which is essentialy an association/manager_ref pair, or an ActiveRecord::Base
    # type object like a Vm.
    #
    # This gives us some flexibility in how we request a resource be refreshed.
    target.targets.each do |target|
      case target
      when MiqTemplate
        add_target(:miq_templates, target.ems_ref)
      when Vm
        add_target(:vms, target.ems_ref)
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end
