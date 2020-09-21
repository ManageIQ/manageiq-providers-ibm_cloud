module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::Cloning
  def log_clone_options(clone_options)
    _log.info('IBM SERVER PROVISIONING OPTIONS: ' + clone_options.to_s)
  end

  def prepare_for_clone_task
    {
      'serverName' => get_option(:vm_target_name) ,
      'imageID'    => get_option_last(:src_vm_id),
      'processors' => get_option_last(:number_of_sockets),
      'procType'   => get_option_last(:instance_type),
      'memory'     => get_option_last(:vm_memory),
      'networks'   => [{"networkID" => get_option(:vlan)}],
      'replicants' => 1,
    }
  end

  def start_clone(clone_options)
    source.with_provider_object(:service => "PowerIaas") do |power_iaas|
      power_iaas.create_pvm_instance(clone_options)[0]['pvmInstanceID']
    end
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
