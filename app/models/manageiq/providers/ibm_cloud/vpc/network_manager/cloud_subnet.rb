class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet < ::CloudSubnet
  include ProviderObjectMixin

  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete, _("The subnet is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
    if number_of(:vms) > 0
      unsupported_reason_add(:delete, _("The subnet has an active %{table}") % {
        :table => ui_lookup(:table => "vm_cloud")
      })
    end
  end

  def raw_delete_cloud_subnet
    with_provider_connection do |connection|
      connection.request(:delete_subnet, :id => ems_ref)
    end
  rescue => err
    _log.error("subnet=[#{name}], error: #{err}")
    raise
  end
end
