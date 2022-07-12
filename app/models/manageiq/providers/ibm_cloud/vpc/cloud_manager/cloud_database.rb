class ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabase < ::CloudDatabase
  supports :create
  supports :delete
  supports :update

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component  => 'text-field',
          :id         => 'name',
          :name       => 'name',
          :isRequired => true,
          :validate   => [{:type => 'required'}],
          :label      => _('Cloud Database Name'),
        },
        {
          :component    => 'select',
          :name         => 'resource_group_name',
          :id           => 'resource_group_name',
          :label        => _('Resource Group'),
          :includeEmpty => true,
          :isRequired   => true,
          :validate     => [{:type => 'required'}],
          :options      => ems.resource_groups.map do |rg|
            {
              :label => rg.name,
              :value => rg.name,
            }
          end,
        },
        {
          :component    => 'select',
          :name         => 'database',
          :id           => 'database',
          :label        => _('Cloud Database Type'),
          :includeEmpty => true,
          :isRequired   => true,
          :validate     => [{:type => 'required'}],
          :options      => ["postgresql", "edb", "mysql", "datastax", "mongodb", "elasticsearch", "redis", "etcd"].map do |db|
            {
              :label => db,
              :value => db,
            }
          end,
        }
      ],
    }
  end

  def params_for_update
    {
      :fields => [
        {
          :component => 'text-field',
          :id        => 'name',
          :name      => 'name',
          :label     => _('Rename Cloud Database'),
        }
      ],
    }
  end

  def self.raw_create_cloud_database(ext_management_system, options)
    ext_management_system.with_provider_connection do |connection|
      resource_group = ext_management_system.resource_groups.find_by!(:name => options["resource_group_name"])
      connection.resource.controller.request(:create_resource_instance,
                                             :name             => options["name"],
                                             :target           => ext_management_system.provider_region,
                                             :resource_group   => resource_group.ems_ref,
                                             :resource_plan_id => "databases-for-#{options["database"]}-standard")
    end
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end

  def raw_delete_cloud_database
    with_provider_connection do |connection|
      connection.resource.controller.request(:delete_resource_instance, :id => ems_ref)
    end
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end

  def raw_update_cloud_database(options)
    with_provider_connection do |connection|
      connection.resource.controller.request(:update_resource_instance, :id => ems_ref, :name => options["name"])
    end
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end
end
