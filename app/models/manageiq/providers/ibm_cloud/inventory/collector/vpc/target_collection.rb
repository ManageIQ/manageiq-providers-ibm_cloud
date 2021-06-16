class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC::TargetCollection < ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def images
    @images ||=
      references(:miq_templates).map do |ems_ref|
        connection.request(:get_image, :id => ems_ref)
      end
  end

  def vms
    @vms ||=
      references(:vms).map do |ems_ref|
        connection.request(:get_instance, :id => ems_ref)
      rescue IBMCloudSdkCore::ApiException
        nil
      end.compact
  end

  def instance_types
    []
  end

  def flavors
    @flavors ||=
      references(:flavors).map do |ems_ref|
        connection.request(:get_instance_profile, :name => ems_ref)
      end
  end

  def keys
    []
  end

  def availability_zones
    @availability_zones ||=
      references(:availability_zones).map do |ems_ref|
        connection.request(:get_region_zone, :region_name => manager.provider_region, :name => ems_ref)
      end
  end

  def security_groups
    @security_groups ||=
      references(:security_groups).map do |ems_ref|
        connection.request(:get_security_group, :id => ems_ref)
      end
  end

  def cloud_networks
    @cloud_networks ||=
      references(:cloud_networks).map do |ems_ref|
        connection.request(:get_vpc, :id => ems_ref)
      end
  end

  def cloud_subnets
    @cloud_subnets ||=
      references(:cloud_subnets).map do |ems_ref|
        connection.request(:get_subnet, :id => ems_ref)
      end
  end

  def floating_ips
    []
  end

  def volumes
    @volumes ||=
      references(:cloud_volumes).map do |ems_ref|
        connection.request(:get_volume, :id => ems_ref)
      end
  end

  def volume_profiles
    []
  end

  def resource_groups
    @resource_groups ||=
      references(:resource_groups).map do |ems_ref|
        connection.cloudtools.resource.manager.request(:get_resource_group, :id => ems_ref)
      end
  end

  private

  def parse_targets!
    # `target` here is an `InventoryRefresh::TargetCollection`.  This contains two types of targets,
    # `InventoryRefresh::Target` which is essentialy an association/manager_ref pair, or an ActiveRecord::Base
    # type object like a Vm.
    #
    # This gives us some flexibility in how we request a resource be refreshed.
    target.targets.each do |target|
      case target
      when MiqTemplate
        add_target(:miq_templates, target.ems_ref)
      when Vm
        add_target(:vms, target.ems_ref)
      when Flavor
        add_target(:flavors, target.ems_ref)
      when AvailabilityZone
        add_target(:availability_zones, target.ems_ref)
      when SecurityGroup
        add_target(:security_groups, target.ems_ref)
      when CloudNetwork
        add_target(:cloud_networks, target.ems_ref)
      when CloudSubnet
        add_target(:cloud_subnets, target.ems_ref)
      when CloudVolume
        add_target(:cloud_volumes, target.ems_ref)
      when ResourceGroup
        add_target(:resource_groups, target.ems_ref)
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end
