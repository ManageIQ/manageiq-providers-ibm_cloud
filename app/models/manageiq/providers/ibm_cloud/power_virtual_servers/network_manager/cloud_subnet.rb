class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet < ::CloudSubnet
  supports :create
  supports :delete do
    _("The Network has active VMIs related to it") if number_of(:vms) > 0
  end

  def self.params_for_create(_ems)
    {
      :fields => [
        {
          :component    => 'select',
          :name         => 'type',
          :id           => 'type',
          :label        => _('Type'),
          :isRequired   => true,
          :validate     => [{:type => 'required'}],
          :initialValue => 'vlan',
          :options      => [
            {
              :label => 'vlan',
              :value => 'vlan',
            },
            {
              :label => 'pub-vlan',
              :value => 'pub-vlan',
            }
          ]
        },
        {
          :component => 'text-field',
          :id        => 'starting_ip_address',
          :name      => 'starting_ip_address',
          :label     => _('Starting IP Address'),
        },
        {
          :component => 'text-field',
          :id        => 'ending_ip_address',
          :name      => 'ending_ip_address',
          :label     => _('Ending IP Address'),
        },
        {
          :component => 'switch',
          :id        => 'jumbo',
          :name      => 'jumbo',
          :label     => _('MTU Jumbo Network'),
          :onText    => _('Enabled'),
          :offText   => _('Disabled'),
        },
      ],
    }
  end

  def self.raw_create_cloud_subnet(ext_management_system, options)
    cloud_instance_id = ext_management_system.parent_manager.uid_ems

    ext_management_system.with_provider_connection(:service => 'PCloudNetworksApi') do |api|
      network = IbmCloudPower::NetworkCreate.new(
        :type        => options[:type] || 'pub-vlan',
        :name        => options[:name],
        :cidr        => options[:cidr],
        :gateway     => options[:gateway_ip],
        :dns_servers => options[:dns_nameservers]
      )

      api.pcloud_networks_post(cloud_instance_id, network)
    end
  rescue IbmCloudPower::ApiError => e
    _log.error("network=[#{options[:name]}], error: #{e}")
    raise
  end

  def raw_delete_cloud_subnet
    cloud_instance_id = ext_management_system.parent_manager.uid_ems
    ext_management_system.with_provider_connection(:service => 'PCloudNetworksApi') do |api|
      api.pcloud_networks_delete(cloud_instance_id, ems_ref)
    end
  rescue => e
    _log.error("network=[#{name}], error: #{e}")
  end
end
