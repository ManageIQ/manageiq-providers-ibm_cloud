# frozen_string_literal: true

# Opts into CloudManager provisioning. Custom logic is separated into module mixins.
class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision < ::MiqProvisionCloud
  include ManageIQ::Providers::IbmCloud::VPC::CloudManager::LoggingMixin # Standardise the logging.
  include Cloning       # Actual provision to cloud.
  include Payload       # Create json payload.
  include StateMachine  # Pre-provision tasks.
end
