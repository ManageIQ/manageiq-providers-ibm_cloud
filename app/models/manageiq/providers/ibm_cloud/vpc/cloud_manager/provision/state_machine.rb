# frozen_string_literal: true

# Methods that control the flow of the provision.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision::StateMachine
  # Called before provision. Send signal for method to be called.
  # @return [void]
  def create_destination
    signal :prepare_provision
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Standard method unused in our provision.
  # @return [Nil]
  def customize_destination
    signal :post_create_destination
  rescue => e
    logger(__method__).log_backtrace(e)
  end
end
