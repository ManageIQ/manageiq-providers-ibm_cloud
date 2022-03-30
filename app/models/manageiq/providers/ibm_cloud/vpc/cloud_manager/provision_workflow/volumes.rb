# frozen_string_literal: true

# Contains the elements used to populate and validate boot volume, attached volumes and new volume related fields.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Volumes
  # These are the keys that are populated in the Volumes tab of the UI.
  # @return [Array<String>]
  def volume_dialog_keys
    %i[volume_name volume_profile volume_size volume_on_instance_delete].freeze
  end

  # Fetch volume profiles from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def storage_type_to_profile(_options = {})
    return {} if ar_ems.nil?

    @storage_type_to_profile ||= string_dropdown(ar_ems.cloud_volume_types, :remove_fields => %w[custom])
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Wait until zone is set, then fetch volumes that have a status of available and reside in that zone.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def cloud_volumes_to_volumes(_options = {})
    return {} if ar_ems.nil?

    zone = field(:placement_availability_zone)
    return {} if zone.nil?

    ar_volumes = ar_ems.cloud_volumes.select { |cloud_volume| cloud_volume[:status] == 'available' && cloud_volume[:availability_zone_id] == zone }
    string_dropdown(ar_volumes)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Perform any needed manipulation and validation for new volume fields.
  # @param values [Hash<Symbol, String>] Hash of all the keys and values submitted in the form.
  # @return [void]
  def parse_new_volumes_fields(values)
    values[:new_volumes] = create_new_volumes_array(values)
    validate_volumes(values[:new_volumes])
  end

  # Select keys that have one of the volume dialog keys followed by a digit.
  # @param values [Hash<Symbol, String>] Hash of all the keys and values submitted in the form.
  # @return [Array<Hash{Symbol => String, Integer}>]
  def create_new_volumes_array(values)
    new_volumes = []
    # Regex to place the field name in the field index and count in the count index.
    keys_regex = /(?<field>#{volume_dialog_keys.join('|')})_(?<count>\d+)/

    values.each do |key, value|
      next if value.nil? || (value.respond_to?(:length) && value.length.zero?)

      reg = key.to_s.match(keys_regex) # 'req' should be nil or a match instance. Match instance has ':field' and ':count' keys.
      next if reg.nil?

      count = reg[:count].to_i
      new_volumes[count] ||= {}

      field = reg[:field].to_sym

      # Use integer if value starts and ends with digits.
      new_volumes[count][field] = value.to_s.match?(/^\d+$/) ? value.to_i : value
    end

    # The volume index starts at 1. Which means index 0 is nil. Compact to get rid of it.
    new_volumes.compact
  rescue => e
    logger(__method__).ui_exception(e, :context_msg => 'Creating new_volume array.')
  end

  # Validate the new volumes fields.
  # @param new_volumes [Array<Hash{Symbol => String, Integer}>]
  # @raise [StandardError] Validation of fields has failed. The error message contains a list of validation errors.
  # @return [void]
  def validate_volumes(new_volumes)
    error_array = []
    new_volumes.each_with_index do |item, zero_index|
      index = zero_index + 1
      validate_volume_required(index, item, error_array)
      validate_volume_name(index, item[:volume_name], error_array)
      validate_volume_size(index, item[:volume_size], error_array)
      validate_volume_profile(index, item[:volume_profile], error_array)
    end
    return nil if error_array.empty?

    e_msg = _("New volumes has the following problems: %{error}") % {:error => error_array.join(", ")}
    raise MiqException::MiqProvisionError, e_msg
  end

  # Validate that volume_name and volume_size are populated. Add a string explaining each violation to error_array.
  # @param index [Integer] Number to print in error messages. Denotes the current UI volume being checked.Denotes the current UI volume being checked.
  # @param item [Hash<Symbol, String>] A new_volume hash.
  # @param error_array [Array<String>] An array of validation error strings.
  # @return [void]
  def validate_volume_required(index, item, error_array)
    logger(__method__).debug("Item is #{item}")
    %i[volume_name volume_size].each do |req|
      next if item.key?(req) # Skip if new_volume hash contains the key the required key.

      e_str = _("Volume %{index} %{field} is required.") % {:index => index, :field => req.to_s}
      error_array.append(e_str)
    end
  end

  # Validate that volume_name conforms to 2 lower-case characters followed by a random number of characters, numbers or dashes.
  # On validation error, add a string explaining the error to error_array.
  # @param index [Integer] Number to print in error messages. Denotes the current UI volume being checked.
  # @param value [String] The value for the volume_name field.
  # @param error_array [Array<String>] An array of validation error strings.
  # @return [void]
  def validate_volume_name(index, value, error_array)
    return nil if value.nil? || value.to_s.match?(/^[a-z][a-z][-a-z0-9]*[a-z0-9]$/)

    e_msg = _("Volume %{index} name '%{value}' must be 3 characters or greater, all lower case, start with two characters, followed by characters, numbers or dash.") % {:index => index, :value => value}
    error_array.append(e_msg)
  end

  # Validate that volume_size is a number between 10 and 2000.
  # On validation error, add a string explaining the error to error_array.
  # @param index [Integer] Number to print in error messages. Denotes the current UI volume being checked.
  # @param value [Integer] The value for the volume_size field.
  # @param error_array [Array<String>] An array of validation error strings.
  # @return [void]
  def validate_volume_size(index, value, error_array)
    return nil if value.nil? || value.to_i.between?(10, 2000)

    e_msg = _("Volume %{index} size '%{value}' must be between 10 and 2000.") % {:index => index, :value => value}
    error_array.append(e_msg)
  end

  # Validate that volume_profile field has a known volume_profile name.
  # On validation error, add a string explaining the error to error_array.
  # @param index [Integer] Number to print in error messages. Denotes the current UI volume being checked.
  # @param value [String] The value for the volume_profile field.
  # @param error_array [Array<String>] An array of validation error strings.
  # @return [void]
  def validate_volume_profile(index, value, error_array)
    return nil if value.nil? || value.to_s.length.zero?

    s_values = storage_type_to_profile.values
    return nil if s_values.include?(value)

    s_str = s_values.join(', ')
    e_msg = _("Volume %{index} profile '%{value}' must be one of %{types}.") % {:index => index, :value => value, :types => s_str}
    error_array.append(e_msg)
  end
end
