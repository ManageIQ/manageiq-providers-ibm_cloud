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
      instance = vpc.instances.instance(ems_ref)
      instance.actions.start
      instance.wait_for do
        update!(:raw_power_state => instance.status)
        instance.started?
      end
    end
  end

  # IBM Cloud does not support suspend. Hiding it from UI.
  supports_not :suspend

  # Send a stop action to IBM Cloud. Wait for state to change to stopped, then update the raw_power_state.
  def raw_stop
    with_provider_connection do |vpc|
      instance = vpc.instances.instance(ems_ref)
      instance.actions.stop
      instance.wait_for do
        update!(:raw_power_state => instance.status)
        instance.stopped?
      end
    end
  end

  # IBM Cloud does not support pause. Using stop since can't hide it in UI.
  def raw_pause
    raw_stop
  end

  # Show reboot in the instance menu when on.
  supports :reboot_guest do
    unsupported_reason_add(:reboot_guest, _('The VM is not powered on')) unless current_state == 'on'
  end

  def raw_reboot_guest
    with_provider_connection do |vpc|
      instance = vpc.instances.instance(ems_ref)
      instance.actions.reboot
      instance.wait_for(:sleep_time => 0.5, :timeout => 60) do
        update!(:raw_power_state => instance.status)
        instance.transitional?
      end
      instance.wait_for do
        update!(:raw_power_state => instance.status)
        instance.started?
      end
    end
  end
end
