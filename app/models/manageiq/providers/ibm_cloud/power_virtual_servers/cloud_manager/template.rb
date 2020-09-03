class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  supports :provisioning do
    if ext_management_system
      unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning)) unless ext_management_system.supports_provisioning?
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  def provider_object(_connection = nil)
    ext_management_system.connect
  end

  def destroy
    delete_image
  end

  def delete_image_queue(userid)
    task_opts = {
      :action => "Deleting Cloud Image for user #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'delete_image',
      :instance_id => id,
      :role        => 'ems_operations',
      :queue_name  => ext_management_system.queue_name_for_ems_operations,
      :zone        => ext_management_system.my_zone,
      :args        => []
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def delete_image
    raw_delete_image
  end

  def raw_delete_image
    ext_management_system.with_provider_connection(:target => 'PowerIaas') do |power_iaas|
      power_iaas.delete_image(ems_ref)
      _log.info("Deleting cloud image=[name: '#{name}', id: '#{ems_ref}']")
    end
  rescue => e
    _log.error("image=[#{name}], error: #{e}")
  end

  def validate_delete_image
    validate_unsupported(_("Delete Cloud Template Operation"))
  end
end
