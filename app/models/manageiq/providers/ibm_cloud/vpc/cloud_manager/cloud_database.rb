class ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabase < ::CloudDatabase
  supports :create
  supports :delete

  def self.raw_create_cloud_database(ext_management_system, options)
    ext_management_system.with_provider_connection do |connection|
      resource_group = ext_management_system.resource_groups.find_by!(:name => options[:resource_group_name])
      connection.resource.controller.request(:create_resource_instance,
                                             :name             => options[:name],
                                             :target           => ext_management_system.provider_region,
                                             :resource_group   => resource_group.ems_ref,
                                             :resource_plan_id => "databases-for-#{options[:database]}-standard")
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
end
