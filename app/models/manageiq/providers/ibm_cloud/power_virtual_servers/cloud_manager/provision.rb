class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision < ::MiqProvisionCloud
  include_concern 'Cloning'
  include_concern 'StateMachine'
end
