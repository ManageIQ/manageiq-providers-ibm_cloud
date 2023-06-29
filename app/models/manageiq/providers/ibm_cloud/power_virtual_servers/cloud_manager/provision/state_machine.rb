module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::StateMachine
  def create_destination
    case request_type
    when 'clone_to_template'
      signal :determine_placement
    else
      signal :prepare_volumes_and_networks
    end
  end

  def prepare_volumes_and_networks
    new_volumes = options[:new_volumes]
    phase_context[:new_volumes] = []

    if new_volumes.any?
      source.with_provider_connection(:service => "PCloudVolumesApi") do |api|
        new_volumes.each do |new_volume|
          new_volume = api.pcloud_cloudinstances_volumes_post(
            cloud_instance_id, IbmCloudPower::CreateDataVolume.new(new_volume)
          )
          phase_context[:new_volumes] << new_volume.volume_id
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

  def determine_placement
    options[:destination] = 'image-catalog'
    signal :start_clone_task
  end

  def start_clone_task
    update_and_notify_parent(:message => "Starting Clone of #{clone_direction}")
    clone_options = prepare_for_clone_task
    log_clone_options(clone_options)
    phase_context[:clone_task_ref] = start_clone(clone_options)
    phase_context.delete(:clone_options)
    signal :poll_clone_complete
  end
end
