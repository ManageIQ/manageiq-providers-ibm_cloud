class ManageIQ::Providers::IbmCloud::Inventory < ManageIQ::Providers::Inventory
  def self.parsed_manager_name(ems, target)
    case target
    when InventoryRefresh::TargetCollection
      "#{ManageIQ::Providers::Inflector.manager_type(ems.class)}::TargetCollection"
    else
      super
    end
  end
end
