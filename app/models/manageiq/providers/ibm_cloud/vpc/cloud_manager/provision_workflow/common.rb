# frozen_string_literal: true

# Contains methods that are used by the workflow instance.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Common
  # Get a new CloudManager object.
  # @raise [MiqException::MiqProvisionError] Unable to get a new object from server.
  # @return [ManageIQ::Providers::IbmCloud::VPC::CloudManager]
  def ar_ems
    return @ar_ems unless @ar_ems.nil?

    rui = resources_for_ui[:ems]
    ems = load_ar_obj(rui) if rui
    raise 'VPC EMS could not be found. Raising an exception.' if ems.nil?

    @ar_ems = ems
  rescue => e
    logger(__method__).log_backtrace(e, :context_msg => 'Fetching ems for VPC cloud.')
  end

  # Required method to display the provision workflow in UI.
  # @param _message [String]
  # @return [void]
  def dialog_name_from_automate(_message = 'get_dialog_name')
  end

  # Do any needed manipulation of the values hash.
  # @param values [Hash] Values for use in provision request.
  # @return [void]
  def set_request_values(values) # rubocop:disable Naming/AccessorMethodName # Standard method in parent.
    parse_new_volumes_fields(values) # See volumes.rb for details.
    super
    logger(__method__).info("Final values is #{values}")
    # Do not rescue. `parse_new_volumes_fields` will throw an exception on validation error.
  end
end
