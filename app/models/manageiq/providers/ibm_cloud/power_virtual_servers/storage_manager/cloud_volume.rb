class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume < ::CloudVolume
  def validate_delete_volume
    msg = validate_volume
    return {:available => msg[:available], :message => msg[:message]} unless msg[:available]
    if status == "in-use"
      return validation_failed("Delete Volume", "Can't delete volume that is in use.")
    end

    {:available => true, :message => nil}
  end

  def raw_delete_volume
    ext_management_system.with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.delete_volume(ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
  end
end
