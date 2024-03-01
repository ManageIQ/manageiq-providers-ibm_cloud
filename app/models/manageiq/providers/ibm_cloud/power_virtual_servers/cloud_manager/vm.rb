class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  include Operations

  supports :capture
  # leverages the logic of native_console
  supports(:console) { unsupported_reason(:native_console) }
  supports :vnc_console
  supports :terminate
  supports :reboot_guest do
    _("The VM is not powered on") unless current_state == "on"
  end
  supports :reset do
    _("The VM is not powered on") unless current_state == "on"
  end
  supports :snapshots
  supports :snapshot_create
  supports :revert_to_snapshot do
    _("Cannot revert to snapshot while VM is running") unless current_state == "off"
  end
  supports :remove_snapshot
  supports :remove_all_snapshots

  supports_not :suspend

  supports :publish do
    unsupported_reason(:action)
  end

  # TODO: converge these all into console and use unsupported_reason(:console) for all
  supports :html5_console do
    if current_state != "on"
      _("VM Console not supported because VM is not powered on")
    else
      unsupported_reason(:native_console)
    end
  end
  supports :launch_html5_console

  supports :native_console do
    unsupported_reason(:action)
  end

  supports :resize do
    return _('The VM is not powered off') unless current_state == "off"
    return _('The VM is not connected to a provider') unless ext_management_system
    return _('SAP VM resize not supported') if flavor.kind_of?(ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SAPProfile)
  end

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

  def params_for_resize
    {
      :fields => [
        {
          :component         => 'select',
          :name              => 'pin_policy',
          :id                => 'pin_policy',
          :label             => _('Pinning'),
          :initializeOnMount => true,
          :initialValue      => form_default_values.find_by(:name => 'pin_policy').value,
          :isRequired        => true,
          :options           => [
            {
              :label => _('None'),
              :value => 'none',
            },
            {
              :label => _('Hard'),
              :value => 'hard',
            },
            {
              :label => _('Soft'),
              :value => 'soft',
            },
          ]
        },
        {
          :component         => 'text-field',
          :name              => 'processors',
          :id                => 'processors',
          :label             => _('Cores'),
          :initializeOnMount => true,
          :initialValue      => form_default_values.find_by(:name => 'entitled_processors').value,
          :type              => 'number',
          :min               => 0.25,
          :step              => 0.25,
          :isRequired        => true,
          :validate          => [
            {:type => 'required'},
            {:type => 'min-number-value', :value => 0.25, :message => _("Size must be greater than or equal to .25")}
          ],
        },
        {
          :component         => 'text-field',
          :name              => 'memory',
          :id                => 'memory',
          :label             => _('Memory (GiB)'),
          :initializeOnMount => true,
          :initialValue      => hardware.memory_mb / 1024,
          :type              => 'number',
          :min               => 2,
          :step              => 1,
          :isRequired        => true,
          :validate          => [
            {:type => 'required'},
            {:type => 'min-number-value', :value => 2, :message => _("Size must be greater than or equal to 2")}
          ],

        },
        {
          :component         => 'radio',
          :name              => 'proc_type',
          :id                => 'proc_type',
          :label             => _('Core Type'),
          :initializeOnMount => true,
          :initialValue      => form_default_values.find_by(:name => 'processor_type').value,
          :isRequired        => true,
          :options           => [
            {
              :label => _('Shared uncapped'),
              :value => 'shared',
            },
            {
              :label => _('Shared capped'),
              :value => 'capped',
            },
            {
              :label => _('Dedicated'),
              :value => 'dedicated',
            },
          ]
        },
      ],
    }
  end

  def form_default_values
    @form_default_values ||= advanced_settings
  end

  def self.calculate_power_state(raw_power_state)
    case raw_power_state
    when "ACTIVE"
      "on"
    else
      "off"
    end
  end

  def console_url
    crn = ERB::Util.url_encode(ext_management_system.pcloud_crn.values.join(":"))
    params = URI.encode_www_form(:paneId => "manageiq", :crn => crn)
    URI::HTTPS.build(:host => "cloud.ibm.com", :path => "/services/power-iaas/#{crn}/server/#{uid_ems}", :query => params)
  end

  private

  def pcloud_pvminstances_action_post(action)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      pvm_instance_action = IbmCloudPower::PVMInstanceAction.new("action" => action)
      api.pcloud_pvminstances_action_post(cloud_instance_id, ems_ref, pvm_instance_action)
    end
  end
end
