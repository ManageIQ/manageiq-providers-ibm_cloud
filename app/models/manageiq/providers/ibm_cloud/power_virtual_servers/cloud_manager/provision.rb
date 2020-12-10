class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision < ::MiqProvisionCloud
  include_concern 'Cloning'
  include_concern 'StateMachine'

  def cloud_instance_id
    source.ext_management_system.uid_ems
  end
end
