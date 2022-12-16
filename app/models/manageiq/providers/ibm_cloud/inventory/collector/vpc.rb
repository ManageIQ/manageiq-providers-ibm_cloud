class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  def connection
    @connection ||= manager.connect
  end

  def vpc
    @vpc ||= connection.vpc(:region => manager.provider_region)
  end

  def databases
    @databases ||= connection.databases(:region => manager.provider_region)
  end

  def vms
    vpc.instances.all
  end

  def vm_key_pairs(vm_id)
    vpc.request(:get_instance_initialization, :id => vm_id) || {}
  end

  def flavors
    vpc.request(:list_instance_profiles)[:profiles]
  end

  def images
    @images ||= vpc.collection(:list_images).to_a
  end

  def images_by_id
    @images_by_id ||= images.index_by { |img| img[:id] }
  end

  def image(image_id)
    vpc.request(:get_image, :id => image_id)
  rescue IBMCloudSdkCore::ApiException
    nil
  end

  def keys
    vpc.request(:list_keys)[:keys]
  end

  def availability_zones
    vpc.request(:list_region_zones, :region_name => manager.provider_region)[:zones]
  end

  def security_groups
    vpc.collection(:list_security_groups)
  end

  def network_acls
    vpc.collection(:list_network_acls)
  end

  def cloud_database_flavors
    ManageIQ::Providers::IbmCloud::DatabaseTypes.all
  end

  def cloud_networks
    vpc.collection(:list_vpcs)
  end

  def cloud_subnets
    vpc.collection(:list_subnets)
  end

  def vpn_gateways
    vpc.collection(:list_vpn_gateways)
  end

  def vpn_gateway_connections(vpn_id)
    vpc.request(:list_vpn_gateway_connections, :vpn_gateway_id => vpn_id)[:connections]
  end

  def floating_ips
    vpc.collection(:list_floating_ips)
  end

  def load_balancers
    vpc.request(:list_load_balancers)[:load_balancers]
  end

  def load_balancer_listeners(load_balancer_id)
    vpc.request(:list_load_balancer_listeners, :load_balancer_id => load_balancer_id)[:listeners]
  end

  def load_balancer_pools(load_balancer_id)
    vpc.request(:list_load_balancer_pools, :load_balancer_id => load_balancer_id)[:pools]
  end

  def load_balancer_pool_members(load_balancer_id, pool_id)
    vpc.request(:list_load_balancer_pool_members,
                :load_balancer_id => load_balancer_id,
                :pool_id          => pool_id)[:members]
  end

  def volumes
    vpc.collection(:list_volumes)
  end

  def volume(volume_id)
    vpc.request(:get_volume, :id => volume_id)
  end

  # Fetch volume profiles from VPC. Each item has following keys :name, :family, :href.
  # @return [Array<Hash<Symbol, String>>]
  def volume_profiles
    vpc.collection(:list_volume_profiles)
  end

  def tags_by_crn(crn)
    retried = false
    begin
      vpc.cloudtools.tagging.collection(:list_tags, :attached_to => crn, :providers => ["ghost"]).to_a
    rescue IBMCloudSdkCore::ApiException => err
      raise if retried || !err.message.match?(/You must wait \d+ ms before you can make ghost-tags get api requests/)

      sleep(5)
      retried = true
      retry
    end
  end

  def database_instances
    @database_instances ||= vpc.cloudtools.resource.controller.collection(:list_resource_instances, :resource_plan_id => 'databases-for-*')
  end

  def database_info(database_id)
    deployment_info = databases.request(:get_deployment_info, :id => database_id)
    scaling_info = databases.request(:list_deployment_scaling_groups, :id => database_id)[:groups].first
    {
      :db_engine    => deployment_info.dig(:deployment, :version),
      :used_storage => scaling_info.dig(:disk, :allocation_mb)&.megabytes,
      :max_storage  => scaling_info.dig(:disk, :maximum_mb)&.megabytes
    }
  rescue IBMCloudSdkCore::ApiException
    nil
  end

  # Fetch resource groups from ResourceController SDK.
  # @return [Enumerator]
  def resource_groups
    vpc.cloudtools.resource.manager.collection(:list_resource_groups)
  end
end
