class ManageIQ::Providers::IbmCloud::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  def self.parsed_manager_name(target)
    case target
    when InventoryRefresh::TargetCollection
      'VPC::TargetCollection'
    else
      super
    end
  end
end
