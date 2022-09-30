module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm::Operations
  extend ActiveSupport::Concern

  def raw_create_snapshot(name, desc = nil, _memory = nil)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      req = IbmCloudPower::SnapshotCreate.new(
        {
          :name        => name,
          :description => desc,
        }
      )
      api.pcloud_pvminstances_snapshots_post(cloud_instance_id, ems_ref, req)
    end
  rescue => err
    create_notification(:vm_snapshot_failure, :error => err.to_s, :snapshot_op => "create")
    raise MiqException::MiqVmSnapshotError, err.to_s
  end

  def raw_resize(options)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      body = IbmCloudPower::PVMInstanceUpdate.new("memory"     => options["memory"].to_i,
                                                  "processors" => options["processors"].to_f,
                                                  "proc_type"  => options["proc_type"],
                                                  "pin_policy" => options["pin_policy"])
      api.pcloud_pvminstances_put(cloud_instance_id, ems_ref, body)
    end
  rescue => err
    create_notification(:vm_resize_error, :error => err.to_s)
    raise MiqException::MiqVmResizeError, err.to_s
  end

  def raw_revert_to_snapshot(snapshot_id)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      snapshot = Snapshot.find(snapshot_id)
      req = IbmCloudPower::SnapshotRestore.new({:force => false}) # would not force restore, if VM is not shut down
      api.pcloud_pvminstances_snapshots_restore_post(cloud_instance_id, ems_ref, snapshot.uid_ems, req)
    end
  rescue => err
    create_notification(:vm_snapshot_failure, :error => err.to_s, :snapshot_op => "restore")
    raise MiqException::MiqVmSnapshotError, err.to_s
  end

  def raw_remove_snapshot(snapshot_id)
    with_provider_connection(:service => 'PCloudSnapshotsApi') do |api|
      snapshot = Snapshot.find(snapshot_id)
      api.pcloud_cloudinstances_snapshots_delete(cloud_instance_id, snapshot.uid_ems)
    end
  rescue => err
    create_notification(:vm_snapshot_failure, :error => err.to_s, :snapshot_op => "delete")
    raise MiqException::MiqVmSnapshotError, err.to_s
  end

  def raw_remove_all_snapshots
    with_provider_connection(:service => 'PCloudSnapshotsApi') do |api|
      snapshots.each do |snapshot|
        api.pcloud_cloudinstances_snapshots_delete(cloud_instance_id, snapshot.uid_ems)
      rescue => err
        create_notification(:vm_snapshot_failure, :error => err.to_s, :snapshot_op => "delete")
        raise MiqException::MiqVmSnapshotError, err.to_s
      end
    end
  rescue => err
    create_notification(:vm_snapshot_failure, :error => err.to_s, :snapshot_op => "delete")
    raise MiqException::MiqVmSnapshotError, err.to_s
  end

  def remote_console_acquire_ticket_queue(protocol, _userid)
    task_opts = {
      :action => "acquiring Instance #{name} #{protocol.to_s.upcase} remote console ticket",
    }

    queue_opts = {
      :instance_id => id,
      :class_name  => self.class.name,
      :method_name => 'remote_console_acquire_ticket',
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :args        => [protocol]
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def remote_console_acquire_ticket(_console_type)
    with_provider_connection(:service => 'PCloudPVMInstancesApi') do |api|
      resp = api.pcloud_pvminstances_console_post(cloud_instance_id, ems_ref)
      raise MiqException::MiqVmError, _("url cannot be nil") if resp.nil? || resp.console_url.nil?

      {:remote_url => resp.console_url, :proto => 'remote'}
    end
  rescue => err
    raise MiqException::MiqVmError, err.to_s
  end
end
