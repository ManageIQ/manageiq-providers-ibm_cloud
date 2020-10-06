module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::Cloning
  def log_clone_options(clone_options)
    _log.info('IBM SERVER PROVISIONING OPTIONS: ' + clone_options.to_s)
  end

  def prepare_for_clone_task
    specs = {
      'serverName' => get_option(:vm_target_name),
      'imageID'    => get_option_last(:src_vm_id),
      'processors' => get_option_last(:entitled_processors).to_f,
      'procType'   => get_option_last(:instance_type),
      'memory'     => get_option_last(:vm_memory).to_i,
      'sysType'    => get_option_last(:sys_type),
      'pinPolicy'  => get_option_last(:pin_policy),
      'migratable' => get_option_last(:migratable) == 1,
      'networks'   => [{"networkID" => get_option(:vlan)}], # TODO: support multiple values
      'replicants' => 1, # TODO: we have to use this field instead of what 'MIQ' does
    }

    # TODO: support multiple values
    ip_addr = get_option_last(:ip_addr)
    specs['networks'][0]['ipAddress'] = ip_addr unless !ip_addr || ip_addr.strip.blank?

    chosen_storage_type = get_option_last(:storage_type)
    specs['storageType'] = chosen_storage_type unless chosen_storage_type == 'None'

    chosen_key_pair = get_option_last(:guest_access_key_pair)
    specs['keyPairName'] = chosen_key_pair unless chosen_key_pair == 'None'

    user_script_text = options[:user_script_text]
    user_script_text64 = Base64.encode64(user_script_text) unless user_script_text.nil?
    specs['userData'] = user_script_text64 unless user_script_text64.nil?

    attached_volumes = options[:cloud_volumes] || []
    attached_volumes.concat(phase_context[:new_volumes]).compact!
    specs['volumeIDs'] = attached_volumes unless attached_volumes.empty?

    specs
  end

  def start_clone(clone_options)
    begin
      source.with_provider_object(:service => "PowerIaas") do |power_iaas|
        power_iaas.create_pvm_instance(clone_options)[0]['pvmInstanceID']
      end
    rescue RestClient::ExceptionWithResponse => e
      raise MiqException::MiqProvisionError, e.response.to_s
    end
  rescue RestClient::ExceptionWithResponse => e
    raise MiqException::MiqProvisionError, e.response.to_s
  end

  def do_clone_task_check(clone_task_ref)
    source.with_provider_object(:service => "PowerIaas") do |power_iaas|
      instance = power_iaas.get_pvm_instance(clone_task_ref)
      instance_state = instance['status']
      stop = false

      case instance_state
      when 'BUILD'
        status = 'The server is being provisioned.'
      when 'ACTIVE'
        stop = (instance['processors'].to_f > 0) && (instance['memory'].to_f > 0)
        status = 'The server has been provisioned.; ' + (stop ? 'Server description available.' : 'Waiting for server description.')
      when 'ERROR'
        raise MiqException::MiqProvisionError, "An error occurred while provisioning the instance."
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
