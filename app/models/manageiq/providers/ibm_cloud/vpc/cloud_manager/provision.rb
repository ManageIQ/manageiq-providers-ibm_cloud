# frozen_string_literal: true

# Opts into CloudManager provisioning. Custom logic is separated into module mixins.
class ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision < ::MiqProvisionCloud
  include ManageIQ::Providers::IbmCloud::VPC::CloudManager::LoggingMixin # Standardise the logging.

  include_concern 'Cloning'       # Actual provision to cloud.
  include_concern 'Payload'       # Create json payload.
  include_concern 'StateMachine'  # Pre-provision tasks.
end
