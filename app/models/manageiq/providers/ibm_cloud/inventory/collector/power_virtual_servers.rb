class ManageIQ::Providers::IbmCloud::Inventory::Collector::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def connection
    @power_iaas ||= manager.connect(:service => "PowerIaas")
  end

  def vms
    connection.get_pvm_instances
  end

  def image(img_id)
    connection.get_image(img_id)
  end

  def images
    connection.get_images
  end

  def volumes
    connection.get_volumes
  end

  def volume(volume_id)
    connection.get_volume(volume_id)
  end

  def networks
    connection.get_networks
  end

  def ports(network_id)
    connection.get_network_ports(network_id)
  end

  def sshkeys
    connection.get_ssh_keys
  end

  def system_pool
    connection.get_system_pool.values
  end

  def storage_types
    # TODO: The Power Cloud API does not yet have a call to retrieve
    # available storage types.
    ::Settings.ems_refresh.ibm_cloud_power_virtual_servers.storage_types
  end
end
