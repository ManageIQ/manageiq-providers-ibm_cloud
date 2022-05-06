class ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolume < ::CloudVolume
  supports :create
  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete_volume, _("The Cloud Volume is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
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
          :step       => 10,
          :isRequired => true,
          :validate   => [{:type => 'required'},
                          {:type => 'min-number-value', :value => 10, :message => _('Size must be greater than or equal to 10')},
                          {:type => 'max-number-value', :value => 2000, :message => _('Size must be lower than or equal to 2000')}],
        },
        {
          :component    => 'select',
          :name         => 'volume_type',
          :id           => 'volume_type',
          :label        => _('Cloud Volume Type'),
          :includeEmpty => true,
          :isRequired   => true,
          :options      => ems.cloud_volume_types.map do |cvt|
            {
              :label => cvt.name,
              :value => cvt.name,
            }
          end,
        },
        {
          :component  => 'text-field',
          :name       => 'iops',
          :id         => 'iops',
          :label      => _('IOPS'),
          :type       => 'number',
          :step       => 100,
          :isRequired => true,
          :condition  => {
            :when => 'volume_type',
            :is   => 'custom',
          },
          :validate   => [{:type => 'required'},
                          {:type => 'min-number-value', :value => 100, :message => _('Number of IOPS must be greater than or equal to 100')}],
        },
        {
          :component    => 'select',
          :name         => 'availability_zone_id',
          :id           => 'availability_zone_id',
          :label        => _('Availability Zone'),
          :includeEmpty => true,
          :options      => ems.parent_manager.volume_availability_zones.map do |az|
            {
              :label => az.name,
              :value => az.name,
            }
          end,
        }
      ],
    }
  end

  def params_for_attach
    {
      :fields => [
        {
          :component => 'text-field',
          :name      => 'device_mountpoint',
          :id        => 'device_mountpoint',
          :label     => _('Device Mountpoint')
        }
      ]
    }
  end

  def self.raw_create_volume(ext_management_system, options)
    options = options.with_indifferent_access
    volume = {
      :profile  => {
        :name => options[:volume_type]
      },
      :zone     => {
        :name => options[:availability_zone_id]
      },
      :name     => options[:name],
      :capacity => options[:size].to_i
    }
    volume[:iops] = options[:iops].to_i if options[:volume_type] == 'custom'

    ext_management_system.with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:create_volume, :volume_prototype => volume)
    end
  rescue => err
    _log.error("cloud_volume=[#{options[:name]}], error: #{err}")
    raise
  end

  def raw_delete_volume
    with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:delete_volume, :id => ems_ref)
    end
  rescue => err
    _log.error("cloud_volume=[#{name}], error: #{err}")
    raise
  end
end
