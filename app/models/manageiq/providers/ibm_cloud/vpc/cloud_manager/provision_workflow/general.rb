# frozen_string_literal: true

# Contains the elements used to populate and validate general fields.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::General
  # Fetch system profiles from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def provision_type_to_profile(_options = {})
    @provision_type_to_profile ||= begin
      flavors = resources_for_ui[:ems] ? ar_ems.flavors : ManageIQ::Providers::IbmCloud::VPC::CloudManager::Flavor.all
      index_dropdown(flavors)
    end
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Validate vm_name field matches the required regex specified by VPC Cloud API doc.
  # @param _field [void]
  # @param _values [void]
  # @param _dlg [void]
  # @param value [String] The value of the field.
  # @return [String, NilClass]  String on error. Nil when valid.
  def validate_vm_name(_field, _values, _dlg, _fld, value)
    return _('General/Instance Name is a required field.') if value.nil? || value.to_s.strip.length.zero?

    msg = _('General/Instance Name must be all lower-case, start with 2 characters, followed by any number of characters, numbers or dashes and end with a character or digit.')
    return msg unless value.to_s.match?(/^[a-z][a-z][-a-z0-9]*[a-z0-9]$/)

    nil
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Fetch SSH keys from inventory.
  # @param _options [void]
  # @return [Array<Hash<String: String>>] An array of hashes with ems_ref as key and name as value.
  def guest_access_key_pairs_to_keys(_options = {})
    @guest_access_key_pairs_to_keys ||= begin
      key_pairs = resources_for_ui[:ems] ? ar_ems.key_pairs : ManageIQ::Providers::IbmCloud::VPC::CloudManager::AuthKeyPair.all
      string_dropdown(key_pairs)
    end
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Fetch resource groups from inventory.
  # @param _options [void]
  # @return [Array<Hash<String: String>>] An array of hashes containing the resource group id and name.
  def resource_groups_to_resource_groups(_options = {})
    @resource_groups_to_resource_groups ||= begin
      resource_groups = resources_for_ui[:ems] ? ar_ems.resource_groups : ManageIQ::Providers::IbmCloud::VPC::CloudManager::ResourceGroup.all
      string_dropdown(resource_groups)
    end
  rescue => e
    logger(__method__).ui_exception(e)
  end
end
