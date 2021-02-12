module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::OptionsHelper
  def cloud_instance_id
    source.ext_management_system.uid_ems
  end

  def vm_image
    @vm_image ||= MiqTemplate.find_by(:id => get_option(:src_vm_id))
  end

  def sap_image?
    vm_image.description == 'stock-sap'
  end
end
