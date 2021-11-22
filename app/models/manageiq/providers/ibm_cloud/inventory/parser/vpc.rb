class ManageIQ::Providers::IbmCloud::Inventory::Parser::VPC < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  def parse
    floating_ips
    cloud_databases
    cloud_database_flavors
    cloud_networks
    cloud_subnets
    vpn_gateways
    load_balancers
    security_groups
    network_acls
    availability_zones
    auth_key_pairs
    flavors
    images
    instances
    volumes
    cloud_volume_types
    resource_groups
  end

  def images
    collector.images.each do |image|
      persister_image = persister.miq_templates.build(
        :uid_ems            => image[:id],
        :ems_ref            => image[:id],
        :name               => image[:name],
        :description        => image&.dig(:operating_system, :display_name),
        :location           => collector.manager.provider_region,
        :vendor             => "ibm_cloud",
        :connection_state   => "connected",
        :raw_power_state    => "never",
        :template           => true,
        :publicly_available => true
      )

      vm_or_template_operating_system(persister_image, image)
    end
  end

  def instances
    collector.vms.each do |instance|
      persister_instance = persister.vms.build(
        :description       => "IBM Cloud Server",
        :ems_ref           => instance[:id],
        :location          => instance&.dig(:zone, :name) || "unknown",
        :genealogy_parent  => persister.miq_templates.lazy_find(instance&.dig(:image, :id)),
        :availability_zone => persister.availability_zones.lazy_find(instance&.dig(:zone, :name)),
        :flavor            => persister.flavors.lazy_find(instance&.dig(:profile, :name)),
        :key_pairs         => instance_key_pairs(instance[:id]),
        :name              => instance[:name],
        :vendor            => "ibm_cloud",
        :connection_state  => "connected",
        :raw_power_state   => instance[:status],
        :uid_ems           => instance[:id]
      )

      instance_hardware(persister_instance, instance)
      instance_operating_system(persister_instance, instance)
      instance_network_interfaces(persister_instance, instance)

      tags = collector.tags_by_crn(instance[:crn])
      vm_and_template_labels(persister_instance, tags)
      vm_and_template_taggings(persister_instance, map_labels("VmIBM", tags))
    end
  end

  def instance_network_interfaces(persister_instance, instance)
    instance[:network_interfaces].each do |nic|
      persister_network_port = persister.network_ports.build(
        :name       => nic[:name],
        :ems_ref    => nic[:id],
        :device_ref => instance[:id],
        :device     => persister_instance
      )

      persister.cloud_subnet_network_ports.build(
        :network_port => persister_network_port,
        :address      => nic[:primary_ipv4_address],
        :cloud_subnet => persister.cloud_subnets.lazy_find(nic&.dig(:subnet, :id))
      )
    end
  end

  def instance_hardware(persister_instance, instance)
    vcpu_count = instance&.dig(:vcpu, :count)
    architecture = instance&.dig(:vcpu, :architecture)
    bitness = architecture.include?("64") ? 64 : 32
    cpus = Float(vcpu_count).ceil if vcpu_count
    memory = instance[:memory]
    memory_mb = Integer(memory) * 1024 if memory
    persister_hardware = persister.hardwares.build(
      :vm_or_template  => persister_instance,
      :cpu_sockets     => cpus,
      :cpu_total_cores => cpus,
      :memory_mb       => memory_mb,
      :bitness         => bitness
    )

    hardware_networks(persister_hardware, instance)
    instance_storage(persister_hardware, instance)
  end

  def instance_storage(persister_hardware, instance)
    instance[:volume_attachments].each do |vol_attach|
      vol = collector.volume(vol_attach&.dig(:volume, :id))
      persister.disks.build(
        :hardware        => persister_hardware,
        :device_name     => vol[:name],
        :device_type     => vol[:type],
        :controller_type => "ibm",
        :backing         => persister.cloud_volumes.lazy_find(vol[:id]),
        :location        => vol[:id],
        :size            => vol[:capacity]&.gigabytes
      )
    end
  end

  def instance_operating_system(persister_instance, instance)
    image_id = instance&.dig(:image, :id)
    image    = collector.images_by_id[image_id] || collector.image(image_id) if image_id

    vm_or_template_operating_system(persister_instance, image) if image
  end

  def vm_or_template_operating_system(vm_or_template, image)
    os_name = image&.dig(:operating_system, :name)

    persister.operating_systems.build(
      :vm_or_template => vm_or_template,
      :product_name   => normalize_os(os_name),
      :version        => os_name
    )
  end

  def hardware_networks(persister_hardware, instance)
    instance[:network_interfaces].each do |nic|
      persister.networks.build(
        :hardware    => persister_hardware,
        :description => "private",
        :ipaddress   => nic[:primary_ipv4_address]
      )
    end
  end

  def vm_and_template_labels(resource, tags)
    tags.each do |tag|
      formatted_tag = get_formatted_tag(tag)
      persister
        .vm_and_template_labels
        .find_or_build_by(
          :resource => resource,
          :name     => formatted_tag[:key]
        )
        .assign_attributes(
          :section => 'labels',
          :source  => 'ibm',
          :value   => formatted_tag[:value]
        )
    end
  end

  def map_labels(model_name, labels)
    label_hashes = labels.collect do |tag|
      formatted_tag = get_formatted_tag(tag)
      {:name => formatted_tag[:key], :value => formatted_tag[:value]}
    end
    persister.tag_mapper.map_labels(model_name, label_hashes)
  end

  def vm_and_template_taggings(resource, tags_inventory_objects)
    tags_inventory_objects.each do |tag|
      persister.vm_and_template_taggings.build(:taggable => resource, :tag => tag)
    end
  end

  def flavors
    collector.flavors.each do |flavor|
      memory = flavor&.dig(:memory, :value)
      disk = flavor[:disks].first&.dig(:size, :value) || 0
      persister.flavors.build(
        :ems_ref         => flavor[:name],
        :name            => flavor[:name],
        :cpu_total_cores => flavor&.dig(:vcpu_count, :value),
        :memory          => memory&.gigabytes,
        :root_disk_size  => disk&.gigabytes,
        :enabled         => true
      )
    end
  end

  def auth_key_pairs
    collector.keys.each do |key|
      persister.auth_key_pairs.build(
        :name        => key[:name],
        :fingerprint => key[:fingerprint],
        :ems_ref     => key[:id]
      )
    end
  end

  def instance_key_pairs(instance_id)
    collector.vm_key_pairs(instance_id)[:keys].to_a.map do |key|
      persister.auth_key_pairs.lazy_find(key[:name])
    end
  end

  def availability_zones
    collector.availability_zones.each do |az|
      persister.availability_zones.build(
        :ems_ref => az[:name],
        :name    => az[:name]
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      persister_security_group = persister.security_groups.build(
        :cloud_network => persister.cloud_networks.lazy_find(sg&.dig(:vpc, :id)),
        :ems_ref       => sg[:id],
        :name          => sg[:name],
        :network_ports => sg[:network_interfaces].to_a.map do |nic|
          persister.network_ports.lazy_find(nic[:id])
        end
      )

      sg[:rules].each do |sg_rule|
        persister.firewall_rules.build(
          :name                  => "#{sg[:name]}-#{sg_rule[:protocol]}-#{sg_rule[:direction]}",
          :ems_ref               => sg_rule[:id],
          :host_protocol         => sg_rule[:protocol],
          :direction             => sg_rule[:direction],
          :source_ip_range       => sg_rule&.dig(:remote, :cidr_block),
          :resource              => persister_security_group,
          :port                  => sg_rule[:port_min],
          :end_port              => sg_rule[:port_max],
          :source_security_group => persister_security_group
        )
      end
    end
  end

  def network_acls
    collector.network_acls.each do |acl|
      acl[:rules].each do |acl_rule|
        persister.cloud_network_firewall_rules.build(
          :name                  => "#{acl&.dig(:vpc, :name)}-#{acl[:name]}-#{acl_rule[:name]}",
          :ems_ref               => acl_rule[:id],
          :host_protocol         => acl_rule[:protocol],
          :direction             => acl_rule[:direction],
          :source_ip_range       => acl_rule[:source],
          :network_protocol      => acl_rule[:action],
          :port                  => nil,
          :end_port              => nil,
          :source_security_group => nil,
          :resource              => persister.cloud_networks.lazy_find(acl&.dig(:vpc, :id))
        )
      end
    end
  end

  def cloud_databases
    collector.database_instances.each do |db|
      db_info = collector.database_info(db[:id])
      persister.cloud_databases.build(
        :ems_ref      => db[:guid],
        :name         => db[:name],
        :status       => db[:state],
        :db_engine    => (db_info[:db_engine] unless db_info.nil?),
        :used_storage => (db_info[:used_storage] unless db_info.nil?),
        :max_storage  => (db_info[:max_storage] unless db_info.nil?)
      )
    end
  end

  def cloud_database_flavors
    collector.cloud_database_flavors.each do |flavor|
      persister.cloud_database_flavors.build(
        :ems_ref => flavor[:name],
        :name    => flavor[:name],
        :enabled => true,
        :cpus    => flavor[:vcpu],
        :memory  => flavor[:memory]
      )
    end
  end

  def cloud_networks
    collector.cloud_networks.each do |cn|
      persister.cloud_networks.build(
        :ems_ref => cn[:id],
        :name    => cn[:name],
        :cidr    => "",
        :enabled => true,
        :status  => cn[:status]
      )
    end
  end

  def cloud_subnets
    collector.cloud_subnets.each do |cs|
      persister.cloud_subnets.build(
        :cloud_network     => persister.cloud_networks.lazy_find(cs&.dig(:vpc, :id)),
        :availability_zone => persister.availability_zones.lazy_find(cs&.dig(:zone, :name)),
        :cidr              => cs[:ipv4_cidr_block],
        :ems_ref           => cs[:id],
        :name              => cs[:name],
        :status            => "active",
        :ip_version        => cs[:ip_version],
        :gateway           => cs&.dig(:public_gateway, :name),
        :network_protocol  => cs[:ip_version]
      )
    end
  end

  def vpn_gateways
    collector.vpn_gateways.each do |vpn|
      collector.vpn_gateway_connections(vpn[:id]).each do |conn|
        persister.network_routers.build(
          :name             => "vpn-#{vpn[:name]}-#{conn[:name]}",
          :ems_ref          => conn[:id],
          :admin_state_up   => conn[:admin_state_up],
          :status           => conn[:status],
          :extra_attributes => {
            :cloud_subnet_id => vpn&.dig(:subnet, :id),
            :peer_address    => conn[:peer_address],
            :gateway_members => vpn[:members]
          }
        )
      end
    end
  end

  # Persist all floating ips in VPC Cloud.
  # @return [void]
  def floating_ips
    collector.floating_ips.each do |ip|
      instance_id = floating_ip_instance_id(ip)
      persister.floating_ips.build(
        :vm               => persister.vms.lazy_find(instance_id),
        :network_port     => persister.network_ports.lazy_find(ip&.dig(:target, :id)),
        :ems_ref          => ip[:id],
        :address          => ip[:address],
        :status           => ip[:status],
        :fixed_ip_address => ip&.dig(:target, :primary_ipv4_address)
      )
    end
  end

  # Use a regex to find the target for a floating ip attached to an instance.
  # @param fip [Hash] A VPC Floating Ip hash.
  # @return [String, NilClass] The Cloud ID of the attached instance. Everything else is nil.
  def floating_ip_instance_id(fip)
    # The target key is only present when there is an attached instance.
    return nil unless fip&.dig(:target, :href)

    # The href is something like "https://<zone>.iaas.cloud.ibm.com/v1/instances/<instance_id>/network_interfaces/<network_interface_id>"
    regex = "/instances/(?<inst_id>.*)/network_interfaces/" # Use string to avoid escaping errors and improve readability.
    match = fip[:target][:href].match(regex)
    return nil if match.nil?

    match[:inst_id]
  end

  def load_balancers
    collector.load_balancers.each do |lb|
      persister_lb = persister.load_balancers.build(
        :name    => lb[:name],
        :ems_ref => lb[:id]
      )
      load_balancer_listeners(persister_lb, lb[:id])
      load_balancer_pools(persister_lb, lb[:id])
    end
  end

  def load_balancer_listeners(persister_lb, load_balancer_id)
    collector.load_balancer_listeners(load_balancer_id).each do |listener|
      persister.load_balancer_listeners.build(
        :ems_ref                  => listener[:id],
        :load_balancer_protocol   => listener[:protocol],
        :instance_protocol        => listener[:protocol],
        :load_balancer_port_range => listener[:port_min]..listener[:port_max],
        :load_balancer            => persister_lb
      )
    end
  end

  def load_balancer_pools(persister_lb, load_balancer_id)
    collector.load_balancer_pools(load_balancer_id).each do |pool|
      persister.load_balancer_pools.build(
        :ems_ref                 => pool[:id],
        :name                    => pool[:name],
        :load_balancer_algorithm => pool[:algorithm],
        :protocol                => pool[:protocol]
      )
      load_balancer_pool_members(load_balancer_id, pool[:id])
      load_balancer_health_checks(persister_lb, pool)
    end
  end

  def load_balancer_pool_members(load_balancer_id, pool_id)
    collector.load_balancer_pool_members(load_balancer_id, pool_id).each do |member|
      persister.load_balancer_pool_members.build(
        :ems_ref => member[:id],
        :address => member&.dig(:target, :address),
        :port    => member[:port]
      )
    end
  end

  def load_balancer_health_checks(persister_lb, pool)
    persister.load_balancer_health_checks.build(
      :ems_ref       => pool[:id],
      :protocol      => pool&.dig(:health_monitor, :type),
      :port          => pool&.dig(:health_monitor, :port),
      :url_path      => pool&.dig(:health_monitor, :url_path),
      :interval      => pool&.dig(:health_monitor, :delay),
      :timeout       => pool&.dig(:health_monitor, :timeout),
      :load_balancer => persister_lb
    )
  end

  def volumes
    collector.volumes.each do |vol|
      az_name = vol&.dig(:zone, :name)
      attachments = vol&.dig(:volume_attachments)
      bootable = attachments.to_a.any? { |vol_attach| vol_attach[:type] == "boot" }
      vol_status = attachments.to_a.length.zero? ? vol[:status] : "#{vol[:status]} (attached)"

      persister.cloud_volumes.build(
        :ems_ref           => vol[:id],
        :name              => vol[:name],
        :status            => vol_status,
        :creation_time     => vol[:created_at],
        :description       => 'IBM Cloud Block-Storage Volume',
        :size              => vol[:capacity]&.gigabytes,
        :bootable          => bootable,
        :availability_zone => persister.availability_zones.lazy_find(az_name)
      )
    end
  end

  # Store VPC volume profiles in cloud_volume_types table. Use name for the ems_ref and name. Use the family as description.
  # @return [void]
  def cloud_volume_types
    collector.volume_profiles.each do |v|
      persister.cloud_volume_types.build(
        :ems_ref     => v[:name],
        :name        => v[:name],
        :description => v[:family]
      )
    end
  end

  # For each resource group save the id as ems_ref and name as name. All other properties are ignored.
  # @return [void]
  def resource_groups
    collector.resource_groups.each do |resource|
      persister.resource_groups.build(
        :ems_ref => resource[:id],
        :name    => resource[:name]
      )
    end
  rescue IBMCloudSdkCore::ApiException => err
    # If the IBM Cloud API key used in the provider definition belongs to a service ID,
    # collecting resource groups will fail as an account_id is required to make the API call
    raise unless err.message.include?("Error: Can not get resource groups without account id in parameter by service id token")

    nil
  end

  # Split tags on the first found colon. If no colons then value is an empty string.
  # @return [Hash<Symbol, String>] Hash with :key as value before colon and :value as everything after.
  def get_formatted_tag(tag)
    # Matches any character as few as possible, a colon, and then everything else. Return two groups key & value.
    regex = /(?<key>.*?):(?<value>.*)/
    # If regex doesn't match then nil is returned and the second hash is created.
    match = tag[:name].to_s.match(regex) || {:key => tag[:name], :value => ''}
    # MatchObjects act like hashes but aren't. Create a new hash.
    {:key => match[:key], :value => match[:value].to_s.strip}
  end

  def normalize_os(os_name)
    return "unknown" if os_name.nil?

    os_name.sub!("red-", "redhat-") if os_name.start_with?("red-")
    OperatingSystem.normalize_os_name(os_name)
  end
end
