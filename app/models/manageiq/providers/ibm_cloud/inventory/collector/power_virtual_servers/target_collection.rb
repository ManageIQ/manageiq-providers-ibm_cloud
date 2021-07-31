class ManageIQ::Providers::IbmCloud::Inventory::Collector::PowerVirtualServers::TargetCollection < ManageIQ::Providers::IbmCloud::Inventory::Collector::PowerVirtualServers
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def availability_zones
    []
  end

  def images
    @images ||= begin
      references(:miq_templates).map do |ems_ref|
        images_api.pcloud_cloudinstances_images_get(cloud_instance_id, ems_ref)
      rescue IbmCloudPower::ApiError => err
        error_message = JSON.parse(err.response_body)["description"]
        _log.debug("ImageID not found: #{error_message}")
        nil
      end
    end
    @images.compact
  end

  def flavors
    []
  end

  def cloud_volume_types
    []
  end

  def volumes
    @volumes ||= begin
      references(:cloud_volumes).map do |ems_ref|
        volumes_api.pcloud_cloudinstances_volumes_get(cloud_instance_id, ems_ref)
      rescue IbmCloudPower::ApiError => err
        error_message = JSON.parse(err.response_body)["description"]
        _log.debug("VolumeID not found: #{error_message}")
        nil
      end
    end
    @volumes.compact
  end

  def pvm_instances_by_id
    @pvm_instances_by_id ||= pvm_instances.index_by(&:pvm_instance_id)
  end

  def pvm_instances
    @pvm_instances ||= begin
      references(:vms).map do |ems_ref|
        pvm_instances_api.pcloud_pvminstances_get(cloud_instance_id, ems_ref)
      rescue IbmCloudPower::ApiError => err
        error_message = JSON.parse(err.response_body)["description"]
        _log.debug("PVMInstanceID not found: #{error_message}")
        nil
      end
    end
    @pvm_instances.compact
  end

  def networks
    @networks ||= begin
      references(:cloud_networks).map do |ems_ref|
        networks_api.pcloud_networks_get(cloud_instance_id, ems_ref)
      rescue IbmCloudPower::ApiError => err
        error_message = JSON.parse(err.response_body)["description"]
        _log.debug("NetworkID not found: #{error_message}")
        nil
      end
    end
    @networks.compact
  end

  def sshkeys
    []
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
      when ManageIQ::Providers::CloudManager::AuthKeyPair
        add_target(:auth_key_pairs, target.ems_ref)
      when AvailabilityZone
        add_target(:availability_zones, target.ems_ref)
      when SecurityGroup
        add_target(:security_groups, target.ems_ref)
      when CloudNetwork
        add_target(:cloud_networks, target.ems_ref)
      when CloudSubnet
        add_target(:cloud_subnets, target.ems_ref)
      when FloatingIp
        add_target(:floating_ips, target.ems_ref)
      when CloudVolume
        add_target(:cloud_volumes, target.ems_ref)
      when CloudVolumeType
        add_target(:cloud_volume_types, target.ems_ref)
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
