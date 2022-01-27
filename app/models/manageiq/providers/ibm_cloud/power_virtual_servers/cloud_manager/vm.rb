class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  include_concern 'Operations'

  supports :terminate
  supports :reboot_guest do
    unsupported_reason_add(:reboot_guest, _("The VM is not powered on")) unless current_state == "on"
  end
  supports :reset do
    unsupported_reason_add(:reset, _("The VM is not powered on")) unless current_state == "on"
  end
  supports :snapshots
  supports :snapshot_create

  supports_not :suspend

  def cloud_instance_id
    ext_management_system.uid_ems
  end

  def raw_start
    pcloud_pvminstances_action_post("start")
    update!(:raw_power_state => "ACTIVE")
  end

  def raw_stop
    pcloud_pvminstances_action_post("stop")
    update!(:raw_power_state => "SHUTOFF")
  end

  def raw_reboot_guest
    pcloud_pvminstances_action_post("soft-reboot")
  end

  def raw_reset
    pcloud_pvminstances_action_post("hard-reboot")
  end

  def raw_destroy
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      api.pcloud_pvminstances_delete(cloud_instance_id, ems_ref)
    end
  end

  def params_for_create_snapshot
    {
      :fields => [
        {
          :component  => 'text-field',
          :name       => 'name',
          :id         => 'name',
          :label      => _('Name'),
          :isRequired => true,
          :validate   => [
            {
              :type => 'required',
            },
            {
              :type    => 'pattern',
              :pattern => '^[a-zA-Z][a-zA-Z0-9_-]*$',
              :message => _('Must contain only alphanumeric, hyphen, and underscore characters'),
            }
          ],
        },
        {
          :component => 'textarea',
          :name      => 'description',
          :id        => 'description',
          :label     => _('Description'),
        },
      ],
    }
  end

  def self.calculate_power_state(raw_power_state)
    case raw_power_state
    when "ACTIVE"
      "on"
    else
      "off"
    end
  end

  private

  def pcloud_pvminstances_action_post(action)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      pvm_instance_action = IbmCloudPower::PVMInstanceAction.new("action" => action)
      api.pcloud_pvminstances_action_post(cloud_instance_id, ems_ref, pvm_instance_action)
    end
  end
end
