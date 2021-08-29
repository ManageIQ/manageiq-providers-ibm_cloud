# frozen_string_literal: true

require 'json'

# Provide all configurable aspects of the actual provision operation.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision::Cloning
  # Called during provision. Prints message to log file.
  # @param clone_options [Hash] Options used for clone operation.
  # @return [Boolean] The result of the log message.
  def log_clone_options(clone_options)
    json_clone_options = JSON.dump(clone_options)
    _log.info("IBM SERVER PROVISIONING OPTIONS: #{json_clone_options}")
  rescue => e
    logger(__method__).log_backtrace(e, :context_msg => 'Error while logging clone options for VPC provision.')
  end

  # Send the final product to the Cloud provider.
  # @param clone_options [Hash] Payload to send to provider.
  # @raise [MiqException::MiqProvisionError] An error was returned by the SDK.
  # @return [String] The ID of the new instance.
  def start_clone(clone_options)
    logger(__method__).debug("Json for VPC provision task. #{JSON.dump(clone_options)}")
    response = source.with_provider_connection do |connect|
      connect.vpc(:region => source.ext_management_system.provider_region)
             .request(:create_instance, :instance_prototype => clone_options)
    end

    if response[:id].nil?
      error_msg = _('An error occurred while requesting the IBM VPC instance provision. Cannot retrieve instance id from returned server response.')
      raise MiqException::MiqProvisionError, error_msg
    end

    response[:id]
  rescue IBMCloudSdkCore::ApiException => e
    raise MiqException::MiqProvisionError, e.to_s
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Check the status of the provision.
  # @param clone_task_ref [String] The UUID for the new provision.
  # @return [Array(Boolean, String)] 2 elements first is boolean when true signals the provision is complete. Second element is a string for logging the current status.
  def do_clone_task_check(clone_task_ref)
    instance = source.with_provider_connection do |connect|
      connect.vpc(:region => source.ext_management_system.provider_region)
             .request(:get_instance, :id => clone_task_ref)
    end

    live_status = instance[:status]
    return false, _('IBM VPC instance provision has no status present.') if live_status.nil?

    status = live_status.downcase
    if status == 'failed'
      error_msg = _('An error occurred while provisioning the IBM VPC instance. Instance has failed status. Check the instance in cloud.ibm.com for more information.')
      raise MiqException::MiqProvisionError, error_msg
    elsif status == 'running'
      return true, _('The IBM VPC instance has been provisioned and has a running status.')
    elsif %w[pausing pending restarting resuming starting stopping].include?(status)
      nil # NoOp: Let the case fall to the end and use the default status.
    else # If we get here then the status is unknown. We should log the oddity and then let the provision try again.
      warn_msg = "Unknown IBM VPC instance status received from the cloud API: '#{status}'"
      method_log.warn(warn_msg)
    end

    return false, _('The IBM VPC instance is being provisioned.')
  rescue => e
    logger(__method__).log_backtrace(e, :context_msg => 'Error while checking the status of the VPC provision.')
  end
end
