class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  # https://cloud.ibm.com/apidocs/vpc#get-instance
  POWER_STATES = {
    "running"    => "on",
    "failed"     => "off",
    "paused"     => "paused",
    "pausing"    => "paused",
    "pending"    => "suspended",
    "restarting" => "reboot_in_progress",
    "resuming"   => "powering_up",
    "starting"   => "powering_up",
    "stopped"    => "off",
    "stopping"   => "powering_down",
    "unknown"    => "terminated"
  }.freeze

  def self.calculate_power_state(raw_power_state)
    POWER_STATES[raw_power_state.to_s] || "terminated"
  end

  def self.display_name(number = 1)
    n_('Instance (IBM)', 'Instances (IBM)', number)
  end

  # Send a start action to IBM Cloud. Wait for state to change to started, then update the raw_power_state.
  def raw_start
    with_provider_connection do |vpc|
      vpc.create_instance_action(:instance_id => ems_ref, :type => "start")
      wait_for(vpc, "running")
    end
  rescue => e
    $ibm_cloud_log.error(e.to_s)
    $ibm_cloud_log.log_backtrace(e)
    raise
  end

  # IBM Cloud does not support suspend. Hiding it from UI.
  supports_not :suspend

  # Send a stop action to IBM Cloud. Wait for state to change to stopped, then update the raw_power_state.
  def raw_stop
    with_provider_connection do |vpc|
      vpc.create_instance_action(:instance_id => ems_ref, :type => "stop")
      wait_for(vpc, "stopped")
    end
  rescue => e
    $ibm_cloud_log.error(e.to_s)
    $ibm_cloud_log.log_backtrace(e)
    raise
  end

  # IBM Cloud does not support pause. Using stop since can't hide it in UI.
  def raw_pause
    raw_stop
  end

  # Show reboot in the instance menu when on.
  supports :reboot_guest do
    unsupported_reason_add(:reboot_guest, _('The VM is not powered on')) unless current_state == 'on'
  end

  # Gracefully reboot the quest.
  # @param force [Boolean] Ungracefully reboot VM.
  def raw_reboot_guest(force: false)
    with_provider_connection do |vpc|
      vpc.create_instance_action(:instance_id => ems_ref, :type => "reboot", :force => force)
      wait_for(vpc, "running")
    end
  rescue => e
    $ibm_cloud_log.error(e.to_s)
    $ibm_cloud_log.log_backtrace(e)
    raise
  end

  # Tell UI to show reset in UI only when VM is on.
  supports :reset do
    unsupported_reason_add(:reset, _('The VM is not powered on')) unless current_state == "on"
  end

  # Force the the VM to restart.
  def raw_reset
    raw_reboot_guest(:force => true)
  end

  private

  # Update the saved status based on the SDK returned status.
  def wait_for(vpc, desired_status)
    loop do
      status = vpc.get_instance(:id => ems_ref)&.result&.dig("status")
      sdk_update_status(status)
      break if status == desired_status
    end
  end

  def sdk_update_status(status)
    if raw_power_state != status
      update!(:raw_power_state => status) if raw_power_state != status
      $ibm_cloud_log.info("VM instance #{ems_ref} state is #{raw_power_state}")
    end
  end
end
