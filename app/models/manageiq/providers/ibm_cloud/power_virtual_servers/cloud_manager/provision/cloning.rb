module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::Cloning
  def log_clone_options(clone_options)
    _log.info('IBM SERVER PROVISIONING OPTIONS: ' + clone_options.to_s)
  end

  def prepare_for_clone_task
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
      specs['server_name']   = get_option(:vm_target_name)
      specs['memory']        = get_option_last(:vm_memory).to_i
      specs['migratable']    = get_option_last(:migratable) == 1
      specs['processors']    = get_option_last(:entitled_processors).to_f
      specs['proc_type']     = get_option_last(:instance_type)
      specs['pin_policy']    = get_option_last(:pin_policy)
      specs['replicants']    = 1 # TODO: we have to use this field instead of what 'MIQ' does
      specs['key_pair_name'] = chosen_key_pair unless chosen_key_pair == 'None'
      specs['storage_type']  = get_option_last(:storage_type)
      specs['sys_type']      = get_option_last(:sys_type)
    end

    # TODO: support multiple values
    ip_addr = get_option_last(:ip_addr)
    specs['networks'][0]['ipAddress'] = ip_addr unless !ip_addr || ip_addr.strip.blank?

    user_script_text = options[:user_script_text]
    user_script_text64 = Base64.encode64(user_script_text) unless user_script_text.nil?
    specs['user_data'] = user_script_text64 unless user_script_text64.nil?

    attached_volumes = options[:cloud_volumes] || []
    attached_volumes.concat(phase_context[:new_volumes]).compact!
    specs['volume_i_ds'] = attached_volumes unless attached_volumes.empty?

    attached_networks = case get_option(:vlan)
                        when 'None'
                          []
                        else
                          [{"networkID" => get_option(:vlan)}] # TODO: support multiple values
                        end
    attached_networks.concat(phase_context[:new_networks]).compact!
    specs['networks'] = attached_networks

    specs
  end

  def start_clone(clone_options)
    begin
      if sap_image?
        source.with_provider_connection(:service => "PCloudSAPApi") do |api|
          body = IbmCloudPower::SAPCreate.new(clone_options)
          response = api.pcloud_sap_post(cloud_instance_id, body)
          response&.first&.pvm_instance_id
        end
      else
        source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
          body = IbmCloudPower::PVMInstanceCreate.new(clone_options)
          response = api.pcloud_pvminstances_post(cloud_instance_id, body)
          response&.first&.pvm_instance_id
        end
      end
    rescue RestClient::ExceptionWithResponse => e
      raise MiqException::MiqProvisionError, e.response.to_s
    end
  rescue RestClient::ExceptionWithResponse => e
    raise MiqException::MiqProvisionError, e.response.to_s
  end

  def do_clone_task_check(clone_task_ref)
    source.with_provider_connection(:service => "PCloudPVMInstancesApi") do |api|
      instance = api.pcloud_pvminstances_get(cloud_instance_id, clone_task_ref)
      instance_state = instance.status
      stop = false

      case instance_state
      when 'BUILD'
        status = 'The server is being provisioned.'
      when 'ACTIVE'
        stop = (instance.processors.to_f > 0) && (instance.memory.to_f > 0)
        status = 'The server has been provisioned.; ' + (stop ? 'Server description available.' : 'Waiting for server description.')
      when 'ERROR'
        raise MiqException::MiqProvisionError, _("An error occurred while provisioning the instance.")
      else
        status = "Unknown server state received from the cloud API: '#{instance_state}'"
        _log.warn(status)
      end

      return stop, status
    end
  end

  def customize_destination
    signal :post_create_destination
  end
end
