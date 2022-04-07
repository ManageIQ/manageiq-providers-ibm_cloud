class ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabase < ::CloudDatabase
  supports :delete

  def raw_delete_cloud_database
    with_provider_connection do |connection|
      connection.resource.controller.request(:delete_resource_instance, :id => ems_ref)
    end
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end
end
