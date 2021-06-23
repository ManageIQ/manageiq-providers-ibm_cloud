class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork < ::CloudNetwork
  include ProviderObjectMixin

  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete_cloud_network, _("The Cloud Network is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
  end

  def raw_delete_cloud_network(_options = {})
    with_provider_connection do |connection|
      connection.request(:delete_vpc, :id => ems_ref)
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
