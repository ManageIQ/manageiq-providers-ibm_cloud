class ManageIQ::Providers::IbmCloud::Inventory::Parser::VPC < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def parse
    floating_ips
    cloud_networks
    cloud_subnets
    security_groups
    availability_zones
    auth_key_pairs
    flavors
    images
    instances
    volumes
  end

  def images
    collector.images.each do |image|
      persister_image = persister.miq_templates.build(
        :uid_ems            => image["id"],
        :ems_ref            => image["id"],
        :name               => image["name"],
        :description        => image&.dig("operating_system", "display_name"),
        :location           => collector.manager.provider_region,
        :vendor             => "ibm",
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
        :ems_ref           => instance["id"],
        :location          => instance&.dig("zone", "name") || "unknown",
        :genealogy_parent  => persister.miq_templates.lazy_find(instance&.dig("image", "id")),
        :availability_zone => persister.availability_zones.lazy_find(instance&.dig("zone", "name")),
        :flavor            => persister.flavors.lazy_find(instance&.dig("profile", "name")),
        :key_pairs         => instance_key_pairs(instance["id"]),
        :name              => instance["name"],
        :vendor            => "ibm",
        :connection_state  => "connected",
        :raw_power_state   => instance["status"],
        :uid_ems           => instance["id"]
      )

      instance_hardware(persister_instance, instance)
      instance_operating_system(persister_instance, instance)
      instance_network_interfaces(persister_instance, instance)

      tags = collector.tags(instance["crn"])
      vm_and_template_labels(persister_instance, tags)
      vm_and_template_taggings(persister_instance, map_labels("VmIBM", tags))
    end
  end

  def instance_network_interfaces(persister_instance, instance)
    instance["network_interfaces"].each do |nic|
      persister_network_port = persister.network_ports.build(
        :name       => nic["name"],
        :ems_ref    => nic["id"],
        :device_ref => instance["id"],
        :device     => persister_instance
      )

      persister.cloud_subnet_network_ports.build(
        :network_port => persister_network_port,
        :address      => nic["primary_ipv4_address"],
        :cloud_subnet => persister.cloud_subnets.lazy_find(nic&.dig("subnet", "id"))
      )
    end
  end

  def instance_hardware(persister_instance, instance)
    vcpu_count = instance&.dig("vcpu", "count")
    architecture = instance&.dig("vcpu", "architecture")
    bitness = architecture.include?("64") ? 64 : 32
    cpus = Float(vcpu_count).ceil if vcpu_count
    memory = instance["memory"]
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
    instance["volume_attachments"].each do |vol_attach|
      vol = collector.volume(vol_attach&.dig("volume", "id"))
      persister.disks.build(
        :hardware        => persister_hardware,
        :device_name     => vol["name"],
        :device_type     => vol["type"],
        :controller_type => "ibm",
        :backing         => persister.cloud_volumes.lazy_find(vol["id"]),
        :location        => vol["id"],
        :size            => vol["capacity"]&.gigabytes
      )
    end
  end

  def instance_operating_system(persister_instance, instance)
    image_id = instance&.dig("image", "id")
    image    = collector.images_by_id[image_id] || collector.image(image_id) if image_id

    vm_or_template_operating_system(persister_instance, image) if image
  end

  def vm_or_template_operating_system(vm_or_template, image)
    os_name = image&.dig("operating_system", "name")

    persister.operating_systems.build(
      :vm_or_template => vm_or_template,
      :product_name   => normalize_os(os_name),
      :version        => os_name
    )
  end

  def hardware_networks(persister_hardware, instance)
    instance["network_interfaces"].each do |nic|
      persister.networks.build(
        :hardware    => persister_hardware,
        :description => "private",
        :ipaddress   => nic["primary_ipv4_address"]
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
          :name     => formatted_tag["key"]
        )
        .assign_attributes(
          :section => 'labels',
          :source  => 'ibm',
          :value   => formatted_tag["value"]
        )
    end
  end

  def map_labels(model_name, labels)
    label_hashes = labels.collect do |tag|
      formatted_tag = get_formatted_tag(tag)
      {:name => formatted_tag["key"], :value => formatted_tag["value"]}
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
      memory = flavor&.dig("memory", "value")
      memory_mb = Integer(memory) * 1024 if memory
      persister.flavors.build(
        :ems_ref   => flavor["name"],
        :name      => flavor["name"],
        :cpus      => flavor&.dig("vcpu_count", "value"),
        :cpu_cores => flavor&.dig("vcpu_count", "value"),
        :memory    => memory_mb,
        :enabled   => true
      )
    end
  end

  def auth_key_pairs
    collector.keys.each do |key|
      persister.auth_key_pairs.build(
        :name        => key["name"],
        :fingerprint => key["fingerprint"]
      )
    end
  end

  def instance_key_pairs(instance_id)
    collector.vm_key_pairs(instance_id).map do |key|
      persister.auth_key_pairs.lazy_find(key["name"])
    end
  end

  def availability_zones
    collector.availability_zones.each do |az|
      persister.availability_zones.build(
        :ems_ref => az["name"],
        :name    => az["name"]
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      persister.security_groups.build(
        :ems_ref       => sg["id"],
        :name          => sg["name"],
        :network_ports => sg["network_interfaces"].to_a.map do |nic|
          persister.network_ports.lazy_find(nic["id"])
        end
      )
    end
  end

  def cloud_networks
    collector.cloud_networks.each do |cn|
      persister.cloud_networks.build(
        :ems_ref => cn["id"],
        :name    => cn["name"],
        :cidr    => "",
        :enabled => true,
        :status  => cn["status"]
      )
    end
  end

  def cloud_subnets
    collector.cloud_subnets.each do |cs|
      persister.cloud_subnets.build(
        :cloud_network    => persister.cloud_networks.lazy_find(cs&.dig("vpc", "id")),
        :cidr             => cs["ipv4_cidr_block"],
        :ems_ref          => cs["id"],
        :name             => cs["name"],
        :status           => "active",
        :ip_version       => cs["ip_version"],
        :network_protocol => cs["ip_version"]
      )
    end
  end

  def floating_ips
    collector.floating_ips.each do |ip|
      persister.floating_ips.build(
        :ems_ref => ip["id"],
        :address => ip["address"],
        :status  => ip["status"]
      )
    end
  end

  def volumes
    collector.volumes.each do |vol|
      az_name = vol&.dig("zone", "name")
      attachments = vol&.dig("volume_attachments")
      bootable = attachments.to_a.any? { |vol_attach| vol_attach["type"] == "boot" }
      vol_status = attachments.to_a.length.zero? ? vol["status"] : "#{vol["status"]} (attached)"

      persister.cloud_volumes.build(
        :ems_ref           => vol["id"],
        :name              => vol["name"],
        :status            => vol_status,
        :creation_time     => vol["created_at"],
        :description       => 'IBM Cloud Block-Storage Volume',
        :size              => vol["capacity"]&.gigabytes,
        :bootable          => bootable,
        :availability_zone => persister.availability_zones.lazy_find(az_name)
      )
    end
  end

  def get_formatted_tag(tag)
    formatted_key, formatted_value = tag["name"]&.split(":")
    {"key" => tag["key"] || formatted_key, "value" => tag["value"] || formatted_value || ""}
  end

  def normalize_os(os_name)
    return "unknown" if os_name.nil?

    os_name.sub!("red-", "redhat-") if os_name.start_with?("red-")
    OperatingSystem.normalize_os_name(os_name)
  end
end
