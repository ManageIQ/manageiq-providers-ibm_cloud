class ManageIQ::Providers::IbmCloud::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  def self.parsed_manager_name(ems, target)
    case target
    when InventoryRefresh::TargetCollection
      "#{ManageIQ::Providers::Inflector.manager_type(ems.class)}::TargetCollection"
    else
      super
    end
  end
end
