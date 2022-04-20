class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision < ::MiqProvisionCloud
  include_concern 'Cloning'
  include_concern 'StateMachine'
  include_concern 'OptionsHelper'

  def destination_type
    case request_type
    when 'template', 'clone_to_vm' then "Vm"
    when 'clone_to_template'       then "Template"
    else                                ""
    end
  end
end
