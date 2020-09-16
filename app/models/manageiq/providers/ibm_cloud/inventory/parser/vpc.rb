class ManageIQ::Providers::IbmCloud::Inventory::Parser::VPC < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager

  def parse
    instances
  end

  def instances
    # Loop through the collected vms
    collector.vms.each do |instance|
      # Build an InventoryObject in the vms inventory collection
      persister.vms.build(
        :description       => "IBM Cloud Server",
        :ems_ref           => instance["id"],
        # :flavor            => "",
        :location          => "unknown",
        :name              => instance["name"],
        :vendor            => "ibm",
        :connection_state  => "connected",
        :raw_power_state   => instance["status"],
        :uid_ems           => instance["id"],
      )
    end
  end
end
