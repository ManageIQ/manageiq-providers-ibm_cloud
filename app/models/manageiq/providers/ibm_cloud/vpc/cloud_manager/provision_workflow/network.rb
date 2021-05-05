# frozen_string_literal: true

require 'ipaddr'

# Contains the elements used to populate and validate networking related fields.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Network
  # Fetch available zones for this region from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def placement_availability_zone_to_zone(_options = {})
    @placement_availability_zone_to_zone ||= index_dropdown(ar_ems.availability_zones)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Fetch VPCs from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def cloud_networks_to_vpc(_options = {})
    @cloud_networks_to_vpc ||= string_dropdown(ar_ems.cloud_networks)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Wait until both the zone and cloud_network fields are set and then fetch subnets from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def cloud_subnets(_options = {})
    method_log = logger(__method__)
    zone = field(:placement_availability_zone)
    cloud_network = field(:cloud_network)

    return {} if zone.nil? || cloud_network.nil?

    method_log.debug("availability_zone value is #{zone} && cloud_network is #{cloud_network}")
    subnets = ar_ems.cloud_subnets.select { |sn| sn[:availability_zone_id] == zone && sn.cloud_network.ems_ref == cloud_network }
    method_log.debug("Subnets are #{subnets}")
    string_dropdown(subnets)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Fetch a list of security groups.
  # @param _options [void]
  # @return [Hash<String, String>] Hash with ems_ref as key and name as value.
  def security_group_to_security_group(_options = {})
    cloud_network = field(:cloud_network)
    return {} if cloud_network.nil?

    ar_security_group = ar_ems.security_groups.select do |security_group|
      security_group.cloud_network.ems_ref == cloud_network
    end
    string_dropdown(ar_security_group)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Validate the given IP address.
  # @param _field [void]
  # @param _values [void]
  # @param _dig [void]
  # @param _fld [void]
  # @param value [String] The value given in the UI.
  def validate_ip_address(_field, _values, _dlg, _fld, value)
    return _('IP is blank') if value.blank?

    begin
      valid = IPAddr.new(value.strip).ipv4?
    rescue IPAddr::InvalidAddressError
      valid = false
    end

    return _('IP-address field has to be either blank or a valid IPv4 address') unless valid
  rescue => e
    logger(__method__).log_backtrace(e)
  end
end
