class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  supports     :reboot_guest
  supports     :terminate
  supports_not :suspend

  def raw_start
    with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.start_pvm_instance(ems_ref)
    end
    update!(:raw_power_state => "on")
  end

  def raw_stop
    with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.stop_pvm_instance(ems_ref)
    end
    update!(:raw_power_state => "off")
  end

  def raw_reboot_guest
    with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.soft_reboot_pvm_instance(ems_ref)
    end
    update!(:raw_power_state => "off")
  end

  def raw_reset
    with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.hard_reboot_pvm_instance(ems_ref)
    end
    update!(:raw_power_state => "off")
  end

  def raw_destroy
    with_provider_connection(:service => 'PowerIaas') do |power_iaas|
      power_iaas.delete_pvm_instance(ems_ref)
    end
  end

  def self.calculate_power_state(raw_power_state)
    case raw_power_state
    when "ACTIVE"
      "on"
    else
      "off"
    end
  end
end
