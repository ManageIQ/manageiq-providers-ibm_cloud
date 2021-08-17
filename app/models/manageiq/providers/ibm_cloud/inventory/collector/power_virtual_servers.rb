class ManageIQ::Providers::IbmCloud::Inventory::Collector::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  def collect
    connection
  end

  def cloud_instance
    @cloud_instance ||= cloud_instances_api.pcloud_cloudinstances_get(cloud_instance_id)
  end

  def pvm_instance(pvm_instance_id)
    pvm_instances_by_id[pvm_instance_id] ||= pvm_instances_api.pcloud_pvminstances_get(cloud_instance_id, pvm_instance_id)
  rescue IbmCloudPower::ApiError => err
    error_message = JSON.parse(err.response_body)["description"]
    _log.debug("PVMInstanceID not found: #{error_message}")
    nil
  end

  def pvm_instances_by_id
    @pvm_instances_by_id ||= {}
  end

  def pvm_instances
    @pvm_instances ||= pvm_instances_api.pcloud_pvminstances_getall(cloud_instance_id).pvm_instances || []
  end

  def image(image_id)
    begin
      images_by_id[image_id] ||= images_api.pcloud_cloudinstances_images_get(cloud_instance_id, image_id)
    rescue IbmCloudPower::ApiError => err
      error_message = JSON.parse(err.response_body)["description"]
      _log.debug("ImageID not found: #{error_message}")
    end

    begin
      images_by_id[image_id] ||= images_api.pcloud_cloudinstances_stockimages_get(cloud_instance_id, image_id)
    rescue IbmCloudPower::ApiError => err
      error_message = JSON.parse(err.response_body)["description"]
      _log.debug("ImageID not found in stock catalog: #{error_message}")
      nil
    end
  end

  def images_by_id
    @images_by_id ||= images_api.pcloud_cloudinstances_images_getall(cloud_instance_id).images.index_by(&:image_id)
  end

  def images
    images_by_id.values
  end

  def image_architecture(image_id)
    image = image(image_id)
    architecture = image&.specifications&.architecture
    if image&.specifications&.endianness == 'little-endian'
      architecture << 'le'
    end
    architecture
  end

  def volumes
    @volumes ||= volumes_api.pcloud_cloudinstances_volumes_getall(cloud_instance_id).volumes || []
  end

  def volume(volume_id)
    volumes_api.pcloud_cloudinstances_volumes_get(cloud_instance_id, volume_id)
  end

  def networks
    @networks ||= networks_api.pcloud_networks_getall(cloud_instance_id).networks || []
  end

  def network(network_id)
    networks_api.pcloud_networks_get(cloud_instance_id, network_id)
  end

  def ports(network_id)
    networks_api.pcloud_networks_ports_getall(cloud_instance_id, network_id).ports || []
  end

  def sap_profiles
    @sap_profiles ||= sap_api.pcloud_sap_getall(cloud_instance_id).profiles || []
  end

  def sshkeys
    @sshkeys ||= tenants_api.pcloud_tenants_get(pcloud_tenant_id).ssh_keys
  end

  def system_pools
    @system_pools ||= system_pools_api.pcloud_systempools_get(cloud_instance_id)
  end

  def storage_types
    @storage_types ||= storage_capacity_api.pcloud_storagecapacity_types_getall(cloud_instance_id)
  end

  private

  def connection
    @connection ||= manager.connect
  end

  def cloud_manager
    manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  end

  def cloud_instance_id
    @cloud_instance_id ||= cloud_manager.uid_ems
  end

  def pcloud_tenant_id
    cloud_manager.pcloud_tenant_id(connection)
  end

  def images_api
    @images_api ||= IbmCloudPower::PCloudImagesApi.new(connection)
  end

  def networks_api
    @networks_api ||= IbmCloudPower::PCloudNetworksApi.new(connection)
  end

  def pvm_instances_api
    @pvm_instances_api ||= IbmCloudPower::PCloudPVMInstancesApi.new(connection)
  end

  def sap_api
    @sap_api ||= IbmCloudPower::PCloudSAPApi.new(connection)
  end

  def storage_capacity_api
    @storage_capacity_api ||= IbmCloudPower::PCloudStorageCapacityApi.new(connection)
  end

  def system_pools_api
    @system_pools_api ||= IbmCloudPower::PCloudSystemPoolsApi.new(connection)
  end

  def tenants_api
    @tenants_api ||= IbmCloudPower::PCloudTenantsApi.new(connection)
  end

  def volumes_api
    @volumes_api ||= IbmCloudPower::PCloudVolumesApi.new(connection)
  end

  def cloud_instances_api
    @cloud_instances_api ||= IbmCloudPower::PCloudInstancesApi.new(connection)
  end
end
