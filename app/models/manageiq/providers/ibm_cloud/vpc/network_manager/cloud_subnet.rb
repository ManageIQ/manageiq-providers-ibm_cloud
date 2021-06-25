class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet < ::CloudSubnet
  include ProviderObjectMixin

  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete, _("The subnet is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
    if number_of(:vms) > 0
      unsupported_reason_add(:delete, _("The subnet has an active %{table}") % {
        :table => ui_lookup(:table => "vm_cloud")
      })
    end
  end

  def delete_cloud_subnet_queue(userid)
    task_opts = {
      :action => "deleting Cloud Subnet for user #{userid}",
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
    with_provider_connection do |connection|
      connection.request(:delete_subnet, :id => ems_ref)
    end
  rescue => err
    _log.error("subnet=[#{name}], error: #{err}")
  end
end
