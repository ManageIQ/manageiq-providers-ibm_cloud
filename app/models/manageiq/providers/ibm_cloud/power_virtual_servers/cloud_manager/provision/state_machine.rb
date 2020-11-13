module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::StateMachine
  def create_destination
    signal :prepare_volumes_and_networks
  end

  def prepare_volumes_and_networks
    new_volumes = options[:new_volumes]
    phase_context[:new_volumes] = []

    if new_volumes.any?
      source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
        new_volumes.each do |new_volume|
          # TODO attach volume
        end
      end
    end

    phase_context[:new_networks] = []

    if options[:public_network][0]
      source.with_provider_connection(:service => "PCloudNetworksApi") do |api|
        new_network_params = IbmCloudPower::NetworkCreate.new(:type => "pub-vlan")
        new_network = api.pcloud_networks_post(cloud_instance_id, new_network_params)
        phase_context[:new_networks] << {"networkID" => new_network.network_id}
      end
    end

    signal :prepare_provision
  end
end
