class ManageIQ::Providers::IbmCloud::Inventory::Collector::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def collect
    connection
  end

  def pvm_instances
    @pvm_instances ||= pvm_instances_api.pcloud_pvminstances_getall(cloud_instance_id).pvm_instances || []
  end

  def pvm_instance(instance_id)
    pvm_instances_api.pcloud_pvminstances_get(cloud_instance_id, instance_id)
  end

  def image(img_id)
    images_api.pcloud_cloudinstances_images_get(cloud_instance_id, img_id)
  end

  def images
    @images ||= images_api.pcloud_cloudinstances_images_getall(cloud_instance_id).images || []
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
    @sshkeys ||= tenants_api.pcloud_tenants_get(tenant_id).ssh_keys
  end

  def system_pools
    @system_pools ||= system_pools_api.pcloud_systempools_get(cloud_instance_id)
  end

  def storage_types
    # TODO: The Power Cloud API does not yet have a call to retrieve
    # available storage types.
    ::Settings.ems_refresh.ibm_cloud_power_virtual_servers.storage_types
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

  def tenant_id
    cloud_manager.tenant_id(connection)
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

  def system_pools_api
    @system_pools_api ||= IbmCloudPower::PCloudSystemPoolsApi.new(connection)
  end

  def tenants_api
    @tenants_api ||= IbmCloudPower::PCloudTenantsApi.new(connection)
  end

  def volumes_api
    @volumes_api ||= IbmCloudPower::PCloudVolumesApi.new(connection)
  end
end
