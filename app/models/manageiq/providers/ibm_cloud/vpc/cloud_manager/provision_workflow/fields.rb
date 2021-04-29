# frozen_string_literal: true

# Contains the standard methods used to format data for inclusion in form fields.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Fields
  # Get the text to be used by the provision, typically the key with the UUID.
  # Fields are stored as arrays with the first element representing the key and the second the display value.
  # @param field_name [Symbol, String] Name of field.
  # @param is_index [Boolean] Return the display value if the field uses a generic index as key.
  # @return [String, Integer, NilClass] The Value of the field.
  def field(field_name, is_index: false)
    v_array = values[field_name.to_sym]
    return nil unless v_array.kind_of?(Array)
    return v_array.last if is_index

    v_array.first
  end

  # Convert an array of hash like objects into a hash with a string as both the key and value.
  # @param provider [#each_with_object]  An object that acts as an array with hash contents.
  # @param key [String | Symbol] The name of the field to query for the key of the returned hash.
  # @param value [String | Symbol] The name of the field to query for the value of the returned hash.
  # @return [Hash<String, String>] A hash containing the values returned by 'key' and 'value' parameters.
  # @return [Hash<String, String>] If an error is encountered then a hash with 'Error' as the key and the exception string as the value will be returned.
  # On error a log message with backtrace will be printed to the log file.
  def string_dropdown(provider, key: :ems_ref, value: :name, remove_fields: [])
    # Get the last caller to use in error logging.
    parent_method = caller(1..1).first.split[-1]
    generic_dropdown(provider, key, value, remove_fields)
  rescue => e
    # Log the error but do not raise an exception. The pulldown will have a string representation of the error.
    logger(__method__).log_backtrace(e, :re_raise => false, :context_msg => "#{parent_method} exception using #{provider.class.name} using #{key} => #{value}")
    {'Error' => e.to_s}
  end

  # Tries to return the contents of the provided key.
  # @param item [Hash] Hash to query.
  # @param key [String | Symbol] The key to look for,
  # @return [String] The contents of the key in the item hash.
  # @return [String] If the key cannot be found the exception string is returned.
  def find_key(item, key)
    item[key.to_sym] || item[key.to_s] || "key #{key} does not exist in Hash"
  rescue => e
    # Log the error but do not raise an exception. The pulldown will have a string representation of the error.
    logger(__method__).log_backtrace(e, :re_raise => false, :context_msg => "#{item.class} had exception using #{key}")
    e.to_s
  end

  # Create a hash with integers as keys.
  # @param provider [#each_with_object]  An object that acts as an array with hash contents.
  # @param key [String | Symbol] The name of the field to query for the key of the returned hash.
  # @param value [String | Symbol] The name of the field to query for the value of the returned hash.
  # @return [Hash<Integer, String>] A hash containing the values returned by 'key' and 'value' parameters.
  # @return [Hash<Integer, String>] If an error is encountered then a hash with 0 as the key and the exception string as the value will be returned.
  # On error a log message with backtrace will be printed to the log file.
  def index_dropdown(provider, key: :id, value: :name)
    # Get the last caller to use in error logging.
    parent_method = caller(1..1).first.split[-1]

    generic_dropdown(provider, key, value)
  rescue => e
    logger(__method__).log_backtrace(e, :re_raise => false, :context_msg => "#{parent_method} exception using #{key} => #{value}")
    {0 => e.to_s}
  end

  # Standardize the dropdown logic so that both methods use this method.
  # @param provider [#each_with_object]  An object that acts as an array with hash contents.
  # @param key [String | Symbol] The name of the field to query for the key of the returned hash.
  # @param value [String | Symbol] The name of the field to query for the value of the returned hash.
  # @param remove_fields [Array<String>] An array of values to ignore. Used for generic filtering.
  # @return [Hash<Integer, String => String>]
  def generic_dropdown(provider, key, value, remove_fields = [])
    raise "#{provider.class} does not respond to 'each_with_object' method." unless provider.respond_to?(:each_with_object)

    provider.each_with_object({}) do |item, obj|
      return_value = find_key(item, value)
      next if remove_fields.include?(return_value)

      obj[find_key(item, key)] = return_value
    end
  end
end
