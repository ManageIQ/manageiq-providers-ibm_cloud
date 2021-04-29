module ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision::OptionsHelper
  # The ID for this EMS.
  # @return [Integer]
  def cloud_instance_id
    source.ext_management_system.uid_ems
  end

  # Get a MiqTemplate instance for the template selected during provision.
  # @return [MiqTemplate]
  def vm_image
    @vm_image ||= MiqTemplate.find_by(:id => get_option(:src_vm_id))
  end
end
