# frozen_string_literal: true

# Encapsulate logging methods into a single mixin.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::LoggingMixin
  # A logger wrapper that can be used as a general interface.
  class LoggingWrapper
    # The error message presented to the UI on unhandled exception.
    # @return [String]
    def default_ui_error_msg
      _('A server-side error occurred in the provisioning workflow, contact your administrator. Use the menu or "instances by Provider" link to cancel this workflow.')
    end

    def default_short_ui_msg
      _('Error fetching data, check server logs.')
    end

    # Define a short-lived object for this method.
    # @param method_name [String] The name of the method calling this logger.
    # @return [void]
    def initialize(method_name)
      @method_name = method_name
    end

    # Send a info message to the configured logger.
    # @param msg [String] A string message to print.
    # @return [void]
    def info(msg)
      $ibm_cloud_log.info(format_message(msg))
    end

    # Send a debug message to the configured logger.
    # @param msg [String] A string message to print.
    # @return [void]
    def debug(msg)
      $ibm_cloud_log.debug(format_message(msg))
    end

    # Send a warn message to the configured logger.
    # @param msg [String] A string message to print.
    # @return [void]
    def warn(msg)
      $ibm_cloud_log.warn(format_message(msg))
    end

    # Send a warn message to the configured logger.
    # @param msg [String] A string message to print.
    # @return [void]
    def error(msg)
      $ibm_cloud_log.error(format_message(msg))
    end

    # Log the backtrace for an exception.
    # @param exception [Exception] The exception object.
    # @param context_msg [String] A message to be printed as an error that provides context for the exception.
    # @param re_raise [Boolean] Whether to raise the original error again.
    # @param send_return [] The object to send as a return value.
    # @return [void]
    def log_backtrace(exception, context_msg: '', re_raise: true, send_return: nil)
      context_msg = 'printing raised exception' if context_msg.length.zero?

      $ibm_cloud_log.error(format_message(context_msg))
      $ibm_cloud_log.log_backtrace(exception)
      raise if re_raise

      send_return
    end

    def ui_exception(exception, context_msg: '')
      log_backtrace(exception, :context_msg => context_msg, :re_raise => false)
      raise MiqException::MiqProvisionError, default_ui_error_msg
    end

    private

    # Append the callers class and method_name to the message.
    # @param msg [String] The message string.
    # @return [String]
    def format_message(msg)
      "#{@method_name} #{msg}"
    end
  end

  # Set the logger for this environment. Use the standard logger when in production. Use the plugin logger for everything else.
  # @return [ManageIQ::Providers::IbmCloud::VPC::CloudManager::LoggingWrapper]
  def logger(method_name)
    LoggingWrapper.new("#{self.class.name}.#{method_name}")
  end
end
