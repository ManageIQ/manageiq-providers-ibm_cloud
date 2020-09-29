class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume < ::CloudVolume
  supports :create

  def self.validate_create_volume(ext_management_system)
    validate_volume(ext_management_system)
  end

  def self.raw_create_volume(ext_management_system, options)
    volume_params = {
      'name'     => options[:name],
      'size'     => options[:size],
      'diskType' => options[:volume_type]
    }

    volume = nil
    ext_management_system.with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      volume = power_iaas.create_volume(volume_params)
    end
    {:ems_ref => volume['volumeID'], :status => volume['state'], :name => volume['name']}
  rescue => e
    _log.error("volume=[#{volume_params}], error: #{e}")
    raise MiqException::MiqVolumeCreateError, e.to_s, e.backtrace
  end

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
