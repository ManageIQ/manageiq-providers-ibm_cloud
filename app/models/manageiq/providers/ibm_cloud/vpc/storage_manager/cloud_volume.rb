class ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolume < ::CloudVolume
  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete_volume, _("The Cloud Volume is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
  end

  def raw_delete_volume
    with_provider_connection do |connection|
      connection.request(:delete_volume, :id => ems_ref)
    end
  rescue => err
    _log.error("cloud_volume=[#{name}], error: #{err}")
    raise
  end
end
