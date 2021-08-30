class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork < ::CloudNetwork
  include ProviderObjectMixin

  supports :create
  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete_cloud_network, _("The Cloud Network is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
  end

  def self.raw_create_cloud_network(ext_management_system, options)
    ext_management_system.with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:create_vpc, :name => options[:name])
    end
  rescue => err
    _log.error("cloud_network=[#{options[:name]}], error: #{err}")
    raise
  end

  def raw_delete_cloud_network(_options = {})
    with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:delete_vpc, :id => ems_ref)
    end
  rescue => err
    notification_options = {
      :subject       => "[#{name}]",
      :error_message => err.to_s
    }
    Notification.create(:type => :cloud_network_delete_error, :options => notification_options)
    raise
  end
end
