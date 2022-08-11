class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume < ::CloudVolume
  supports :create
  supports :clone
  supports :delete do
    unsupported_reason_add(:delete, _("the volume is not connected to an active Provider")) unless ext_management_system
    unsupported_reason_add(:delete, _("cannot delete volume that is in use.")) if status == "in-use"
  end
  supports_not :snapshot_create
  supports_not :update
  supports :attach do
    unsupported_reason_add(:attach, _("the volume is not connected to an active Provider")) unless ext_management_system
    unsupported_reason_add(:attach, _("cannot attach non-shareable volume that is in use.")) if status == "in-use" && !multi_attachment
  end
  supports :detach do
    unsupported_reason_add(:detach, _("the volume is not connected to an active Provider")) unless ext_management_system
    unsupported_reason_add(:detach, _("the volume status is '%{status}' but should be 'in-use'") % {:status => status}) unless status == "in-use"
  end

  def available_vms
    availability_zone.vms.select { |vm| vm.format == volume_type }
  end

  def cloud_instance_id
    ext_management_system.parent_manager.uid_ems
  end

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component  => 'text-field',
          :name       => 'size',
          :id         => 'size',
          :label      => _('Size (in bytes)'),
          :type       => 'number',
          :step       => 1.gigabytes,
          :isRequired => true,
          :validate   => [{:type => 'required'}, {:type => 'min-number-value', :value => 0, :message => _('Size must be greater than or equal to 0')}],
        },
        {
          :component => 'switch',
          :name      => 'multi_attachment',
          :id        => 'multi_attachment',
          :label     => _('Shareable'),
          :onText    => _('Yes'),
          :offText   => _('No'),
        },
        {
          :component    => 'select',
          :name         => 'affinity_policy',
          :id           => 'affinity_policy',
          :label        => _('Affinity Policy'),
          :initialValue => 'Off',
          :options      => [
            {
              :label => _('Off'),
              :value => 'Off',
            },
            {
              :label => _('Affinity'),
              :value => 'affinity',
            },
            {
              :label => _('Anti-affinity'),
              :value => 'anti-affinity',
            },
          ],
        },
        {
          :component    => 'select',
          :name         => 'volume_type',
          :id           => 'volume_type',
          :label        => _('Cloud Volume Type'),
          :validate     => [{:type => 'required'}],
          :condition    => {
            :when    => 'affinity_policy',
            :pattern => '^Off$',
          },
          :includeEmpty => true,
          :options      => ems.cloud_volume_types.map do |cvt|
            {
              :label => cvt.description,
              :value => cvt.name,
            }
          end,
        },
        {
          :component    => 'select',
          :name         => 'affinity_type',
          :id           => 'affinity_type',
          :label        => _('Affinity Type'),
          :includeEmpty => true,
          :condition    => {
            :not => [
              {
                :when    => 'affinity_policy',
                :pattern => '^Off$',
              },
            ]
          },
          :options      => [
            {
              :label => _('Volume'),
              :value => 'volume',
            },
            {
              :label => _('PVM Instance'),
              :value => 'pvm_instance',
            },
          ],
        },
        {
          :component    => 'select',
          :isSearchable => true,
          :name         => 'affinity_volume',
          :id           => 'affinity_volume',
          :label        => _('Affinity Volume'),
          :validate     => [{:type => 'required'}],
          :condition    => {
            :and => [
              {
                :when    => 'affinity_policy',
                :pattern => '^affinity$',
              },
              {
                :when    => 'affinity_type',
                :pattern => 'volume$',
              },
            ]
          },
          :includeEmpty => true,
          :options      => ems.cloud_volumes.map do |cv|
            {
              :label => cv.name,
              :value => cv.ems_ref,
            }
          end,
        },
        {
          :component    => 'select',
          :isMulti      => true,
          :isClearable  => true,
          :isSearchable => true,
          :name         => 'anti_affinity_volumes',
          :id           => 'anti_affinity_volumes',
          :label        => _('Anti-Affinity Volume(s)'),
          :validate     => [{:type => 'required'}],
          :condition    => {
            :and => [
              {
                :when    => 'affinity_policy',
                :pattern => '^anti-affinity$',
              },
              {
                :when    => 'affinity_type',
                :pattern => 'volume$',
              },
            ]
          },
          :includeEmpty => true,
          :options      => ems.cloud_volumes.map do |cv|
            {
              :label => cv.name,
              :value => cv.ems_ref,
            }
          end,
        },
        {
          :component    => 'select',
          :isSearchable => true,
          :name         => 'affinity_pvm_instance',
          :id           => 'affinity_pvm_instance',
          :label        => _('Affinity PVM Instance'),
          :validate     => [{:type => 'required'}],
          :condition    => {
            :and => [
              {
                :when    => 'affinity_policy',
                :pattern => '^affinity$',
              },
              {
                :when    => 'affinity_type',
                :pattern => 'pvm_instance$',
              },
            ]
          },
          :includeEmpty => true,
          :options      => ems.parent_manager.vms.map do |vm|
            {
              :label => vm.name,
              :value => vm.ems_ref,
            }
          end,
        },
        {
          :component    => 'select',
          :isMulti      => true,
          :isClearable  => true,
          :isSearchable => true,
          :name         => 'anti_affinity_pvm_instances',
          :id           => 'anti_affinity_pvm_instances',
          :label        => _('Anti-Affinity PVM Instance(s)'),
          :validate     => [{:type => 'required'}],
          :condition    => {
            :and => [
              {
                :when    => 'affinity_policy',
                :pattern => '^anti-affinity$',
              },
              {
                :when    => 'affinity_type',
                :pattern => 'pvm_instance$',
              },
            ]
          },
          :includeEmpty => true,
          :options      => ems.parent_manager.vms.map do |vm|
            {
              :label => vm.name,
              :value => vm.ems_ref,
            }
          end,
        },
      ],
    }
  end

  def params_for_clone
    {
      :fields => [
        {
          :component  => 'text-field',
          :name       => 'name',
          :id         => 'name',
          :label      => _('Volume Base Name'),
          :isRequired => true,
          :helperText => _("Base name of the new cloned volume. The cloned Volume name will be prefixed with 'clone-' and suffixed with '-#####' (where ##### is a 5 digit random number)"),
        },
      ]
    }
  end

  def params_for_attach
    {
      :fields => []
    }
  end

  def self.raw_create_volume(ext_management_system, options)
    volume = nil
    volume_params = nil
    affinity_volume = nil
    anti_affinity_volumes = nil
    affinity_pvm_instance = nil
    anti_affinity_pvm_instances = nil

    affinity_policy = options['affinity_policy'] == 'Off' ? nil : options['affinity_policy']

    case affinity_policy
    when 'affinity'
      case options['affinity_type']
      when 'volume'
        affinity_volume = options['affinity_volume']['value']
      when 'pvm_instance'
        affinity_pvm_instance = options['affinity_pvm_instance']['value']
      end
    when 'anti-affinity'
      case options['affinity_type']
      when 'volume'
        anti_affinity_volumes = options['anti_affinity_volumes'].map { |vol| vol['value'] }
      when 'pvm_instance'
        anti_affinity_pvm_instances = options['anti_affinity_pvm_instances'].map { |vol| vol['value'] }
      end
    end

    ext_management_system.with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      volume_params = IbmCloudPower::CreateDataVolume.new(
        'name'                        => options['name'],
        'size'                        => options['size'].to_i / 1.0.gigabyte,
        'disk_type'                   => options['volume_type'],
        'shareable'                   => options['multi_attachment'],
        'affinity_policy'             => affinity_policy,
        'affinity_volume'             => affinity_volume,
        'anti_affinity_volumes'       => anti_affinity_volumes,
        'affinity_pvm_instance'       => affinity_pvm_instance,
        'anti_affinity_pvm_instances' => anti_affinity_pvm_instances
      )

      volume = api.pcloud_cloudinstances_volumes_post(
        ext_management_system.parent_manager.uid_ems,
        volume_params
      )
    end
    {:ems_ref => volume.volume_id, :status => volume.state, :name => volume.name}
  rescue => e
    _log.error("volume=[#{volume_params}], error: #{e}")
    raise MiqException::MiqVolumeCreateError, e.to_s, e.backtrace
  end

  def raw_delete_volume
    ext_management_system.with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_cloudinstances_volumes_delete(cloud_instance_id, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeDeleteError, e.to_s, e.backtrace
  end

  def raw_attach_volume(vm_ems_ref, _device = nil)
    with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_pvminstances_volumes_post(cloud_instance_id, vm_ems_ref, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeAttachError, _("Unable to attach volume: %{error_message}") % {:error_message => e.message}
  end

  def raw_detach_volume(vm_ems_ref)
    with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_pvminstances_volumes_delete(cloud_instance_id, vm_ems_ref, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeDetachError, _("Unable to detach volume: %{error_message}") % {:error_message => e.message}
  end

  def raw_clone_volume(options)
    options[:volume_ids] = [ems_ref]
    with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      clone_volume_params = IbmCloudPower::VolumesCloneAsyncRequest.new(
        :name        => options['name'],
        :volume_ids => options[:volume_ids]
      )
      api.pcloud_v2_volumes_clone_post(
        cloud_instance_id,
        clone_volume_params
      )
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeCloneError, e.to_s, e.backtrace
  end
end
