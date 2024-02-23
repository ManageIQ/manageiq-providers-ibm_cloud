# frozen_string_literal: true

# Provide CloudManager support for IBM CLoud VPC templates.
class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  include ManageIQ::Providers::IbmCloud::VPC::CloudManager::VmOrTemplateShared

  supports :provisioning do
    if ext_management_system
      ext_management_system.unsupported_reason(:provisioning)
    else
      _('not connected to ems')
    end
  end

  # Method used to translate pluralized.
  # @param number [Integer] 1 for singular, 2 for plural.
  # @return [String] The desired format.
  def self.display_name(number = 1)
    n_('Image (VPC)', 'Images (VPC)', number)
  end
end
