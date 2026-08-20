module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::StateMachine
  def create_destination
    case request_type
    when 'clone_to_template'
      options[:destination] = 'image-catalog'
      signal :prepare_provision
    else
      signal :prepare_volumes_and_networks
    end
  end

  # Override the core cloud state machine's poll_clone_complete to handle the
  # case where make_request_clone returned an array of pvm_instance_ids
  # (replicants > 1).  For a single VM the behaviour is identical to core.
  def poll_clone_complete
    clone_status, status_message = do_clone_task_check(phase_context[:clone_task_ref])

    status_message = "completed; post provision work queued" if clone_status
    message = "Clone of #{clone_direction} is #{status_message}"
    _log.info(message)
    update_and_notify_parent(:message => message)

    if clone_status
      clone_task_ref = phase_context.delete(:clone_task_ref)
      ids = Array(clone_task_ref)

      # Store the first ID as new_vm_ems_ref so the core poll_destination_in_vmdb
      # machinery can locate the destination VM after inventory refresh lands.
      phase_context[:new_vm_ems_ref] = ids.first

      manager = source.ext_management_system

      if manager.allow_targeted_refresh?
        target_collection = InventoryRefresh::TargetCollection.new(:manager => manager)
        ids.each { |id| target_collection.add_target(:association => :vms, :manager_ref => {:ems_ref => id}) }
        EmsRefresh.queue_refresh(target_collection)
      else
        EmsRefresh.queue_refresh(manager)
      end

      signal :poll_destination_in_vmdb
    else
      requeue_phase
    end
  end

  def prepare_volumes_and_networks
    new_volumes = options[:new_volumes]
    pass = get_option(:pass)
    phase_context[:new_volumes] = []

    if new_volumes.any?
      source.with_provider_connection(:service => "PCloudVolumesApi") do |api|
        new_volumes.each_with_index do |new_volume, idx|
          # Build a zero-padded 3-digit sequential name so volumes are clearly
          # identifiable in the PowerVS console.
          # Pattern: "<user-base><NNN>" e.g. "datavol001", "datavol002"
          # The counter combines vol-index and pass to stay unique across
          # multiple VMs in the same provisioning request.
          seq = "%03d" % (((pass.to_i - 1) * new_volumes.size) + idx + 1)
          volume_payload = new_volume.merge(:name => "#{new_volume[:name]}#{seq}")
          created_volume = api.pcloud_cloudinstances_volumes_post(
            cloud_instance_id, IbmCloudPower::CreateDataVolume.new(volume_payload)
          )
          phase_context[:new_volumes] << created_volume.volume_id
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
