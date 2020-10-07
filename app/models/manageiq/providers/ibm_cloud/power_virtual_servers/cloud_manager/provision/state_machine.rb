module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::StateMachine
  def create_destination
    signal :prepare_volumes_and_networks
  end

  def prepare_volumes_and_networks
    new_volumes = options[:new_volumes]
    phase_context[:new_volumes] = []

    if new_volumes.any?
      source.with_provider_object(:service => "PowerIaas") do |power_iaas|
        new_volumes.each do |new_volume|
          phase_context[:new_volumes] << power_iaas.create_volume(new_volume)['volumeID']
        end
      end
    end

    phase_context[:new_networks] = []

    if options[:public_network][0]
      source.with_provider_object(:service => "PowerIaas") do |power_iaas|
        new_network = power_iaas.create_network('type' => 'pub-vlan')
        phase_context[:new_networks] << {"networkID" => new_network['networkID']}
      end
    end

    signal :prepare_provision
  end
end
