# frozen_string_literal: true

# Contains methods that are used by the workflow instance.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Common
  # Get a new CloudManager object.
  # @raise [MiqException::MiqProvisionError] Unable to get a new object from server.
  # @return [ManageIQ::Providers::IbmCloud::VPC::CloudManager]
  def ar_ems
    rui = resources_for_ui[:ems]
    ems = load_ar_obj(rui) if rui

    ems
  end

  # Required method to display the provision workflow in UI.
  # @param _message [String]
  # @return [void]
  def dialog_name_from_automate(message = 'get_dialog_name')
    super(message, {'platform' => 'ibm_vpc'})
  end

  # Do any needed manipulation of the values hash.
  # @param values [Hash] Values for use in provision request.
  # @return [void]
  def set_request_values(values) # rubocop:disable Naming/AccessorMethodName # Standard method in parent.
    validate_fields_no_errors(values)
    parse_new_volumes_fields(values) # See volumes.rb for details.
    super
    logger(__method__).debug("Final values is #{values}")
  rescue MiqException::MiqProvisionError # Allow the exception thrown by validation to be re-raised.
    raise
  rescue => e # Log any other errors and return default ui exception message.
    logger(__method__).ui_exception(e)
  end

  # Validate each dropdown value and ensure that they don't have the default short error message.
  # @param values [Hash] Values for use in provision request.
  # @raise [StandardError] A field has the error message. Cancel the form submission.
  # @return [void]
  def validate_fields_no_errors(values)
    logger_message = logger(__method__).default_short_ui_msg
    values.each_value do |value|
      next unless value.kind_of?(Array)
      raise _('A server-side error prevents this form from being submitted. Contact your administrator. To leave this form use the Cancel button.') if value.include?(logger_message)
    end
  end
end
