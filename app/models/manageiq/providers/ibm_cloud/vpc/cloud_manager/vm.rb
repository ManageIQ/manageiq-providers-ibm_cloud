class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  # https://cloud.ibm.com/apidocs/vpc#get-instance
  POWER_STATES = {
    "running"       => "on",
    "failed"        => "off",
    "paused"        => "suspended",
    "pausing"       => "suspended",
    "pending"       => "suspended",
    "restarting"    => "powering_up",
    "resuming"      => "powering_up",
    "starting"      => "powering_up",
    "stopped"       => "off",
    "stopping"      => "powering_down",
    "unknown"       => "terminated"
  }.freeze

  def self.calculate_power_state(raw_power_state)
    POWER_STATES[raw_power_state.to_s] || "terminated"
  end
end
