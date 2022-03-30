# frozen_string_literal: true

# Contains the elements used to populate and validate networking related fields.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow::Network
  # Fetch available zones for this region from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def placement_availability_zone_to_zone(_options = {})
    return {} if ar_ems.nil?

    @placement_availability_zone_to_zone ||= index_dropdown(ar_ems.availability_zones)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Fetch VPCs from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def cloud_networks_to_vpc(_options = {})
    return {} if ar_ems.nil?

    @cloud_networks_to_vpc ||= string_dropdown(ar_ems.cloud_networks)
  rescue => e
    logger(__method__).ui_exception(e)
  end

  # Wait until both the zone and cloud_network fields are set and then fetch subnets from inventory.
  # @param _options [void]
  # @return [Hash] Hash with ems_ref as key and name as value.
  def cloud_subnets(_options = {})
    return {} if ar_ems.nil?

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
  # @return [Hash<Integer, String>] Hash with id as key and name as value.
  def security_group_to_security_group(_options = {})
    return {} if ar_ems.nil?

    cloud_network = field(:cloud_network)
    return {} if cloud_network.nil?

    ar_security_group = ar_ems.security_groups.select { |security_group| security_group.cloud_network.ems_ref == cloud_network }
    index_dropdown(ar_security_group)
  rescue => e
    logger(__method__).ui_exception(e)
  end
end
