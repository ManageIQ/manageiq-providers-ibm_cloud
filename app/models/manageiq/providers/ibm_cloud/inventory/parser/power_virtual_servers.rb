class ManageIQ::Providers::IbmCloud::Inventory::Parser::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  attr_reader :subnet_to_ext_ports

  OS_MIQ_NAMES_MAP = {
    'aix'    => 'unix_aix',
    'rhcos'  => 'linux_coreos',
    'ibmi'   => 'ibm_i',
    'redhat' => 'linux_redhat',
    'rhel'   => 'linux_redhat',
    'sles'   => 'linux_suse'
  }.freeze

  def initialize
    super
    @subnet_to_ext_ports = {}
  end

  def parse
    ext_management_system
    availability_zones
    images
    flavors
    cloud_volume_types
    volumes
    pvm_instances
    networks
    sshkeys
    placement_groups
    snapshots
    shared_processor_pools
  end

  def ext_management_system
    persister.ext_management_system.build(
      :guid            => persister.manager.guid,
      :provider_region => collector.provider_region
    )
  end

  def pvm_instances
    collector.pvm_instances.each do |instance_reference|
      instance = collector.pvm_instance(instance_reference.pvm_instance_id)
      flavor = instance.sap_profile ? instance.sap_profile.profile_id : instance.sys_type

      # saving general VMI information
      ps_vmi = persister.vms.build(
        :availability_zone => persister.availability_zones.lazy_find(persister.cloud_manager.uid_ems),
        :description       => _("PVM Instance"),
        :ems_ref           => instance.pvm_instance_id,
        :ems_created_on    => instance.creation_date,
        :flavor            => persister.flavors.lazy_find(flavor),
        :location          => _("unknown"),
        :name              => instance.server_name,
        :vendor            => "ibm_power_vs",
        :connection_state  => "connected",
        :raw_power_state   => instance.status,
        :uid_ems           => instance.pvm_instance_id,
        :format            => instance.storage_type,
        :placement_group   => persister.placement_groups.lazy_find(instance.placement_group),
        :resource_pool     => persister.resource_pools.lazy_find(instance.shared_processor_pool_id)
      )

      # saving hardware information (CPU, Memory, etc.)
      ps_hw = persister.hardwares.build(
        :vm_or_template  => ps_vmi,
        :cpu_total_cores => instance.virtual_cores&.assigned,
        :cpu_type        => collector.image_architecture(instance.image_id),
        :bitness         => 64,
        :memory_mb       => instance.memory * 1024,
        :guest_os        => OS_MIQ_NAMES_MAP[instance.os_type]
      )

      # saving instance disk information
      instance.volume_ids.to_a.each do |vol_id|
        volume = collector.volume(vol_id)
        next if volume.nil?

        persister.disks.build(
          :hardware        => ps_hw,
          :device_name     => volume.name,
          :device_type     => volume.disk_type,
          :controller_type => "ibm",
          :backing         => persister.cloud_volumes.lazy_find(vol_id),
          :location        => vol_id,
          :size            => volume.size&.gigabytes
        )
      end

      # saving OS information
      persister.operating_systems.build(
        :vm_or_template => ps_vmi,
        :product_name   => OS_MIQ_NAMES_MAP[instance.os_type],
        :version        => instance.operating_system
      )

      # saving exteral network ports
      external_ports = instance.networks.reject { |net| net.external_ip.blank? }
      external_ports.each do |ext_port|
        net_id = ext_port.network_id
        subnet_to_ext_ports[net_id] ||= []
        subnet_to_ext_ports[net_id] << ext_port
      end

      # saving processor type and amount
      persister.vms_and_templates_advanced_settings.build(
        :resource     => ps_vmi,
        :name         => 'entitled_processors',
        :display_name => _('Entitled Processors'),
        :description  => _('The number of entitled processors assigned to the VM'),
        :value        => instance.processors,
        :read_only    => true
      )

      # saving processor type
      persister.vms_and_templates_advanced_settings.build(
        :resource     => ps_vmi,
        :name         => 'processor_type',
        :display_name => _('Processor type'),
        :description  => _('dedicated: Dedicated, shared: Uncapped shared, capped: Capped shared'),
        :value        => instance.proc_type,
        :read_only    => true
      )

      # saving pin_policy
      persister.vms_and_templates_advanced_settings.build(
        :resource     => ps_vmi,
        :name         => 'pin_policy',
        :display_name => _('Pin Policy'),
        :description  => _('VM pinning policy to use [none, soft, hard]'),
        :value        => instance.pin_policy,
        :read_only    => true
      )

      ldesc = software_licenses_description(instance.software_licenses)
      ldesc.present? && persister.vms_and_templates_advanced_settings.build(
        :resource     => ps_vmi,
        :name         => 'software_licenses',
        :display_name => _('Software Licenses'),
        :description  => _('Software Licenses'),
        :value        => ldesc,
        :read_only    => true
      )
    end
  end

  def images
    collector.images.each do |image|
      ps_image = persister.miq_templates.build(
        :uid_ems            => image.image_id,
        :ems_ref            => image.image_id,
        :name               => image.name,
        :description        => image.specifications.image_type,
        :location           => "unknown",
        :vendor             => "ibm_power_vs",
        :raw_power_state    => "never",
        :template           => true,
        :storage_profile_id => persister.cloud_volume_types.lazy_find(image.storage_type),
        :format             => image.storage_type
      )

      persister.operating_systems.build(
        :vm_or_template => ps_image,
        :product_name   => OS_MIQ_NAMES_MAP[image.specifications.operating_system]
      )
    end
  end

  def volumes
    collector.volumes.each do |vol|
      persister.cloud_volumes.build(
        :availability_zone => persister.availability_zones.lazy_find(persister.cloud_manager.uid_ems),
        :ems_ref           => vol.volume_id,
        :name              => vol.name,
        :status            => vol.state,
        :bootable          => vol.bootable,
        :creation_time     => vol.creation_date,
        :description       => _('IBM Cloud Block-Storage Volume'),
        :volume_type       => vol.disk_type,
        :size              => vol.size&.gigabytes,
        :multi_attachment  => vol.shareable
      )
    end
  end

  def networks
    collector.networks.each do |network_ref|
      network = collector.network(network_ref.network_id)

      persister_cloud_networks = persister.cloud_networks.build(
        :ems_ref => "#{network.network_id}-#{network.type}",
        :name    => "#{network.name}-#{network.type}",
        :cidr    => "",
        :enabled => true,
        :status  => 'active'
      )

      persister_cloud_subnet = persister.cloud_subnets.build(
        :cloud_network     => persister_cloud_networks,
        :cidr              => network.cidr,
        :ems_ref           => network.network_id,
        :gateway           => network.gateway,
        :name              => network.name,
        :status            => "active",
        :dns_nameservers   => network.dns_servers,
        :ip_version        => '4',
        :network_protocol  => 'IPv4',
        :availability_zone => persister.availability_zones.lazy_find(persister.cloud_manager.uid_ems),
        :network_type      => network.type
      )

      mac_to_port = {}

      collector.ports(network.network_id).each do |port|
        vmi_id = port.pvm_instance&.pvm_instance_id

        persister_network_port = persister.network_ports.build(
          :name        => port.port_id,
          :ems_ref     => port.port_id,
          :status      => port.status,
          :mac_address => port.mac_address,
          :device_ref  => vmi_id,
          :device      => persister.vms.lazy_find(vmi_id)
        )

        mac_to_port[port.mac_address] = persister_network_port

        persister.cloud_subnet_network_ports.build(
          :network_port => persister_network_port,
          :address      => port.ip_address,
          :cloud_subnet => persister_cloud_subnet
        )
      end

      external_ports = subnet_to_ext_ports[network.network_id] || []
      external_ports.each do |port|
        port_ps = mac_to_port[port.mac_address]

        persister.cloud_subnet_network_ports.build(
          :network_port => port_ps,
          :address      => port.external_ip,
          :cloud_subnet => persister_cloud_subnet
        )
      end
    end
  end

  def placement_groups
    collector.placement_groups.placement_groups.each do |sgrp|
      persister.placement_groups.build(
        :availability_zone => persister.availability_zones.lazy_find(persister.cloud_manager.uid_ems),
        :name              => sgrp.name,
        :policy            => sgrp.policy,
        :ems_ref           => sgrp.id
      )
    end
  end

  def sshkeys
    require "sshkey"
    collector.sshkeys.each do |tkey|
      persister.auth_key_pairs.build(
        :name        => tkey.name,
        :public_key  => tkey.ssh_key,
        :fingerprint => SSHKey.sha1_fingerprint(tkey.ssh_key.split("\n").first)
      )
    end
  end

  def flavors
    collector.system_pools.each_value do |value|
      persister.flavors.build(
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType",
        :ems_ref => value.type,
        :name    => value.type
      )
    end
    if collector.cloud_instance.capabilities.include?('sap')
      collector.sap_profiles.each do |value|
        description = ''
        if value.certified
          description = 'certified'
        end

        persister.flavors.build(
          :type            => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SAPProfile",
          :ems_ref         => value.profile_id,
          :name            => value.profile_id,
          :cpu_total_cores => value.cores,
          :memory          => value.memory&.gigabytes,
          :description     => description
        )
      end
    end
  end

  def cloud_volume_types
    # get only the active storage
    collector.storage_types.storage_types_capacity.each do |v|
      persister.cloud_volume_types.build(
        :type        => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolumeType",
        :ems_ref     => v.storage_type,
        :name        => v.storage_type,
        :description => v.storage_type
      )
    end
  end

  def availability_zones
    # Single availability zone per PowerVS Cloud Manager
    persister.availability_zones.build(
      :name    => persister.cloud_manager.name,
      :ems_ref => persister.cloud_manager.uid_ems
    )
  end

  def snapshots
    collector.snapshots.each do |snapshot|
      # API does not return the total size of snapshot so we have to sum the size of the associated volumes
      total_size = snapshot.volume_snapshots.keys.sum { |vol| collector.volume(vol).size&.gigabytes.to_i }
      persister.snapshots.build(
        :uid            => snapshot.snapshot_id,
        :uid_ems        => snapshot.snapshot_id,
        :ems_ref        => snapshot.snapshot_id,
        :name           => snapshot.name,
        :description    => snapshot.description,
        :total_size     => total_size,
        :create_time    => snapshot.creation_date,
        :vm_or_template => persister.vms.lazy_find(snapshot.pvm_instance_id)
      )
    end
  end

  def shared_processor_pools
    collector.shared_processor_pools.shared_processor_pools.each do |pool|
      params = {
        :uid_ems            => pool.id,
        :ems_ref            => pool.id,
        :name               => pool.name,
        :cpu_shares         => pool.allocated_cores,
        :cpu_reserve        => pool.available_cores,
        :cpu_reserve_expand => true,
        :cpu_limit          => pool.allocated_cores + pool.available_cores,
        :is_default         => false
      }
      persister.resource_pools.build(params)
    end
  end

  def software_licenses_description(software_licenses)
    return "" if software_licenses.nil?

    ldesc = ""
    ldesc = "IBMi Cloud Storage Solution (ibmiCSS), " if software_licenses.ibmi_css
    ldesc << "IBMi Power High Availability (ibmiPHA), " if software_licenses.ibmi_pha

    if software_licenses.ibmi_rds_users
      ldesc << "IBMi Rational Dev Studio (ibmiRDS)"
      ldesc << " - (%d User Licenses)" % [software_licenses.ibmi_rds_users] if software_licenses.ibmi_rds_users
      ldesc << ", "
    end

    ldesc << "IBMi Cloud Storage Solution (ibmiDBQ), " if software_licenses.ibmi_dbq
    ldesc.chomp!(", ")
    ldesc
  end
end
