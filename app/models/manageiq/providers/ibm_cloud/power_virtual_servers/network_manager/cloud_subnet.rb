class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet < ::CloudSubnet
  supports :create

  supports :delete do
    if number_of(:vms) > 0
      unsupported_reason_add(:delete, _("The Network has active VMIs related to it"))
    end
  end

  def delete_cloud_subnet_queue(userid)
    task_opts = {
      :action => "creating cloud subnet, userid: #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_delete_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => []
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_delete_cloud_subnet
    ext_management_system.with_provider_connection({:service => 'PowerIaas'}) do |net_control|
      net_control.del_subnet(ems_ref)
    end
  rescue => e
    _log.error("network=[#{name}], error: #{e}")
  end
end
