# frozen_string_literal: true

# Class contains all logic used to populate the UI.
class ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow < ::MiqProvisionCloudWorkflow
  include ManageIQ::Providers::IbmCloud::VPC::CloudManager::LoggingMixin # Standardise the logging.
  include Common  # Provides common functionality.
  include General # Used for general options.
  include Network # Used for network options.
  include Volumes # Used for volume options.
  include Fields  # Used for manipulating field hashes.

  # Class methods. Do not move to sub module.
  class << self
    # Sets the model to use for Provisioning.
    # @return [ManageIQ::Providers::IbmCloud::VPC::CloudManager]
    def provider_model
      ManageIQ::Providers::IbmCloud::VPC::CloudManager
    end
  end
end
