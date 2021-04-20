class ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume < ::CloudVolume
  supports :create
  supports_not :snapshot_create
  supports_not :update

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
          :component    => 'select',
          :name         => 'volume_type',
          :id           => 'volume_type',
          :label        => _('Cloud Volume Type'),
          :includeEmpty => true,
          :condition    => {
            :when => 'edit',
            :is   => false,
          },
          :options      => ems.cloud_volume_types.map do |cvt|
            {
              :label => cvt.description,
              :value => cvt.name,
            }
          end,
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
          :condition    => {
            :when => 'edit',
            :is   => false,
          },
          :options      => [
            {
              :label => 'Off',
              :value => 'Off',
            },
            {
              :label => 'Affinity',
              :value => 'affinity',
            },
            {
              :label => 'Anti-affinity',
              :value => 'anti-affinity',
            },
          ],
        },
        {
          :component    => 'select',
          :name         => 'affinity_volume_id',
          :id           => 'affinity_volume_id',
          :label        => _('Affinity Volume'),
          :isRequired   => true,
          :validate     => [{:type => 'required'}],
          :includeEmpty => true,
          :condition    => {
            :and => [
              {
                :not => {
                  :when => 'affinity_policy',
                  :is   => 'Off',
                },
              },
              {
                :when => 'edit',
                :is   => false,
              },
            ],
          },
          :options      => ems.cloud_volumes.map do |cv|
            {
              :value => cv.name,
              :label => cv.name,
            }
          end,
        },
      ],
    }
  end

  def self.validate_create_volume(ext_management_system)
    validate_volume(ext_management_system)
  end

  def self.raw_create_volume(ext_management_system, options)
    volume = nil
    volume_params = nil
    ext_management_system.with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      volume_params = IbmCloudPower::CreateDataVolume.new(
        'name'            => options['name'],
        'size'            => options['size'].to_i / 1.0.gigabyte,
        'disk_type'       => options['volume_type'],
        'shareable'       => options['multi_attachment'],
        'affinity_policy' => options['affinity_policy'] == 'Off' ? nil : options['affinity_policy'],
        'affinity_volume' => options['affinity_policy'] == 'Off' ? nil : options['affinity_volume_id']
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

  def validate_delete_volume
    msg = validate_volume
    return {:available => msg[:available], :message => msg[:message]} unless msg[:available]
    if status == "in-use"
      return validation_failed(_("Delete Volume"), _("Can't delete volume that is in use."))
    end

    {:available => true, :message => nil}
  end

  def raw_delete_volume
    ext_management_system.with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_cloudinstances_volumes_delete(cloud_instance_id, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
  end

  def validate_attach_volume
    msg = validate_volume_available
    return {:available => msg[:available], :message => msg[:message]} unless msg[:available]

    if status == "in-use" && !multi_attachment
      return validation_failed(_("Attach Volume"), _("Can't attach non-shareable volume that is in use."))
    end

    {:available => true, :message => nil}
  end

  def raw_attach_volume(vm_ems_ref, _device = nil)
    with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_pvminstances_volumes_post(cloud_instance_id, vm_ems_ref, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeAttachError, _("Unable to attach volume: %{error_message}") % {:error_message => e.message}
  end

  def validate_detach_volume
    validate_volume_in_use
  end

  def raw_detach_volume(vm_ems_ref)
    with_provider_connection(:service => 'PCloudVolumesApi') do |api|
      api.pcloud_pvminstances_volumes_delete(cloud_instance_id, vm_ems_ref, ems_ref)
    end
  rescue => e
    _log.error("volume=[#{name}], error: #{e}")
    raise MiqException::MiqVolumeDetachError, _("Unable to detach volume: %{error_message}") % {:error_message => e.message}
  end
end
