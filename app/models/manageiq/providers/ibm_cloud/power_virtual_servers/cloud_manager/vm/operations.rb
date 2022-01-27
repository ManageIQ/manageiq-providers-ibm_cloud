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
end
