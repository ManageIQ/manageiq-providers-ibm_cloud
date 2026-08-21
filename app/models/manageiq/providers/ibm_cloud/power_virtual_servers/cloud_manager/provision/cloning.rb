module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::Cloning
  def log_clone_options(clone_options)
    _log.info('IBM SERVER PROVISIONING OPTIONS: ' + clone_options.to_s)
  end

  def prepare_for_clone_task
    request_type == 'clone_to_template' ? prepare_for_clone_to_template : prepare_for_clone
  end

  def start_clone(clone_options)
    if request_type == 'clone_to_template'
      make_request_clone_to_template(clone_options)
    elsif sap_image?
      make_request_clone_sap_vm(clone_options)
    else
      make_request_clone(clone_options)
    end
  rescue IbmCloudPower::ApiError => err
    error_message = JSON.parse(err.response_body)["description"] || err.message
    _log.error("VM start_clone error: #{error_message}")
    raise MiqException::MiqProvisionError, error_message
  end

  def do_clone_task_check(clone_task_ref)
    request_type == 'clone_to_template' ? check_task_clone_to_template(clone_task_ref) : check_task_clone(clone_task_ref)
  end

  def customize_destination
    signal :post_create_destination
  end

  def find_destination_in_vmdb(ems_ref)
    return if phase_context[:cloud_api_completion_time].nil? || source.ext_management_system.last_refresh_date < phase_context[:cloud_api_completion_time]

    if request_type == 'clone_to_template'
      # ems_ref is actually a Job ID
      source.ext_management_system&.vms_and_templates&.find_by(:name => options[:vm_name], :template => true)
    else
      source.ext_management_system&.vms_and_templates&.find_by(:ems_ref => ems_ref, :template => false)
    end
  end

  private

  def prepare_for_clone_to_template
    {
      'capture_name'        => get_option(:vm_target_name),
      'capture_destination' => get_option(:destination),
    }
  end

  def prepare_for_clone
    replicants = get_option(:replicants)

    specs = {
      'image_id'   => get_option_last(:src_vm_id),
      'pin_policy' => get_option_last(:pin_policy),
    }

    chosen_key_pair = get_option_last(:guest_access_key_pair)

    if sap_image?
      specs['name']         = get_option(:vm_target_name)
      specs['profile_id']   = get_option_last(:sys_type)
      specs['ssh_key_name'] = chosen_key_pair unless chosen_key_pair == 'None'
    else
      specs['server_name']             = get_option(:vm_target_name)
      specs['memory']                  = get_option_last(:vm_memory).to_i
      specs['processors']              = get_option_last(:entitled_processors).to_f
      specs['proc_type']               = get_option_last(:instance_type)
      specs['pin_policy']              = get_option_last(:pin_policy)
      specs['replicant_naming_scheme'] = 'suffix' if replicants > 1
      specs['key_pair_name']           = chosen_key_pair unless chosen_key_pair == 'None'
      specs['storage_type']            = get_option_last(:storage_type)
      specs['sys_type']                = get_option_last(:sys_type)
      # Pre-created volumes may be placed in any storage pool by PowerVS.
      # Disabling storage pool affinity allows the VM to attach volumes from
      # different pools, preventing "all volumes are not in the same storage pool" errors.
      specs['storage_pool_affinity'] = false
    end
    # When the count of VMs is more than 1, treat it as a multi-VM provision request with replicas
    # placement_group and shared_processor_pool fields are no longer relevant
    # replicants and replicant_affinity_policy(defaults to none) fields are relevant
    if replicants > 1
      specs['replicants'] = replicants
      policy = get_option(:colocation_policy)
      specs['replicant_affinity_policy'] = policy if policy.present? && policy != 'none'
    else
      specs['placement_group'] = get_option(:placement_group) unless get_option(:placement_group).nil?
      specs['shared_processor_pool'] = get_option(:shared_processor_pool) unless get_option(:shared_processor_pool).nil?
    end
    user_script_text = options[:user_script_text]
    user_script_text64 = Base64.encode64(user_script_text) unless user_script_text.nil?
    specs['user_data'] = user_script_text64 unless user_script_text64.nil?

    attached_volumes = options[:cloud_volumes] || []
    attached_volumes.concat(phase_context[:new_volumes]).compact!
    specs['volume_ids'] = attached_volumes unless attached_volumes.empty?

    attached_networks = case get_option(:vlan)
                        when 'None'
                          []
                        else
                          [{"networkID" => get_option(:vlan)}] # TODO: support multiple values
                        end
    attached_networks.concat(phase_context[:new_networks]).compact!
    specs['networks'] = attached_networks

    # TODO: support multiple values
    ip_addr = get_option_last(:ip_addr)
    specs['networks'][0]['ipAddress'] = ip_addr if ip_addr.present?

    specs
  end

  def make_request_clone_to_template(clone_options)
    source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
      vm = Vm.find(get_option(:src_vm_id))
      body = IbmCloudPower::PVMInstanceCapture.new(clone_options)
      response = api.pcloud_v2_pvminstances_capture_post(cloud_instance_id, vm.uid_ems, body)
      response.id
    end
  end

  def make_request_clone_sap_vm(clone_options)
    source.with_provider_connection(:service => "PCloudSAPApi") do |api|
      body = IbmCloudPower::SAPCreate.new(clone_options)
      response = api.pcloud_sap_post(cloud_instance_id, body)
      response&.first&.pvm_instance_id
    end
  end

  def make_request_clone(clone_options)
    source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
      body = IbmCloudPower::PVMInstanceCreate.new(clone_options)
      response = api.pcloud_pvminstances_post(cloud_instance_id, body)
      response&.filter_map(&:pvm_instance_id)
    end
  end

  def check_task_clone_to_template(clone_task_ref)
    source.with_provider_connection(:service => 'PCloudJobsApi') do |api|
      job = api.pcloud_cloudinstances_jobs_get(source.ext_management_system.uid_ems, clone_task_ref)
      stop = (job.status.state == 'completed')
      phase_context[:cloud_api_completion_time] = Time.zone.now.utc if stop
      status = job.status.message.nil? ? job.status.state : "#{job.status.state} Message: '#{job.status.message}'"
      return stop, status
    end
  end

  def check_task_clone(clone_task_ref)
    ids = Array(clone_task_ref)

    source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
      statuses = ids.map do |id|
        instance = api.pcloud_pvminstances_get(cloud_instance_id, id)
        [id, instance.status, instance.processors.to_f, instance.memory.to_f]
      rescue IbmCloudPower::ApiError => e
        # The instance may not be queryable immediately after creation (transient
        # 500s are common in the first few seconds).  Treat it as still building.
        _log.warn("Transient error polling instance #{id}: #{e.message}. Will retry.")
        [id, 'BUILD', 0, 0]
      end

      errored = statuses.select { |_, state, _, _| state == 'ERROR' }
      raise MiqException::MiqProvisionError, _("An error occurred while provisioning the instance.") if errored.any?

      building = statuses.select { |_, state, _, _| state == 'BUILD' }
      active   = statuses.select { |_, state, cpus, mem| state == 'ACTIVE' && cpus > 0 && mem > 0 }
      all_done = building.empty? && active.length == ids.length

      phase_context[:cloud_api_completion_time] = Time.zone.now.utc if all_done

      status = if building.any?
                 "#{building.length} of #{ids.length} instance(s) still provisioning."
               elsif all_done
                 "All #{ids.length} instance(s) provisioned and active."
               else
                 "#{active.length} of #{ids.length} instance(s) active, waiting for full description."
               end

      return all_done, status
    end
  rescue IbmCloudPower::ApiError => err
    # Handle HTTP 500 errors during VM initialization (e.g., BDM attachment in progress)
    if err.code.to_i == 500 && err.response_body.to_s.include?("in process of bdm attachment")
      _log.info("VM is still initializing (attaching block devices), will retry")
      return false, "VM initializing, attaching storage..."
    else
      raise
    end
  end

  def create_and_attach_affinity_volumes(vm_ems_ref, vm_instance_name)
    new_volumes = options[:new_volumes] || []
    return if new_volumes.empty?

    phase_context[:new_volumes] ||= []

    source.with_provider_connection(:service => "PCloudVolumesApi") do |api|
      new_volumes.each do |new_volume|
        volume_params = new_volume.merge(
          :affinity_policy       => "affinity",
          :affinity_pvm_instance => vm_instance_name
        )

        created_volume = api.pcloud_cloudinstances_volumes_post(
          cloud_instance_id,
          IbmCloudPower::CreateDataVolume.new(volume_params)
        )

        begin
          api.pcloud_pvminstances_volumes_post(cloud_instance_id, vm_ems_ref, created_volume.volume_id)
          phase_context[:new_volumes] << created_volume.volume_id
        rescue IbmCloudPower::ApiError
          _log.warn("Failed to attach volume #{created_volume.volume_id} to #{vm_ems_ref}, deleting orphaned volume")
          api.pcloud_cloudinstances_volumes_delete(cloud_instance_id, created_volume.volume_id)
          raise
        end
      end
    end
  end
end
