# frozen_string_literal: true

# Provide CloudManager support for IBM CLoud VPC templates.
class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  include_concern 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::VmOrTemplateShared'

  supports :provisioning do
    if ext_management_system
      unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning)) unless ext_management_system.supports_provisioning?
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  # Get a new CloudTool VPC object.
  # @param connection [ManageIQ::Providers::IbmCloud::CloudTools::Vpc] An existing connection.
  # @return [ManageIQ::Providers::IbmCloud::CloudTools::Vpc] The passed in connection or a new one.
  def provider_object(connection = nil)
    connection || ext_management_system.connect
  end

  # Method used to translate pluralized.
  # @param number [Integer] 1 for singular, 2 for plural.
  # @return [String] The desired format.
  def self.display_name(number = 1)
    n_('Image (VPC)', 'Images (VPC)', number)
  end
end
