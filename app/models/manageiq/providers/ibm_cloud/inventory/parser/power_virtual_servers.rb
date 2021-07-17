class ManageIQ::Providers::IbmCloud::Inventory::Parser::PowerVirtualServers < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  attr_reader :subnet_to_ext_ports

  OS_MIQ_NAMES_MAP = {
    'aix'    => 'unix_aix',
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
    availability_zones
    images
    flavors
    cloud_volume_types
    volumes
    pvm_instances
    networks
    sshkeys
  end

  def pvm_instances
    collector.pvm_instances.each do |instance_reference|
      instance = collector.pvm_instance(instance_reference.pvm_instance_id)

      # saving general VMI information
      ps_vmi = persister.vms.build(
        :availability_zone => persister.availability_zones.lazy_find(persister.cloud_manager.uid_ems),
        :description       => _("PVM Instance"),
        :ems_ref           => instance.pvm_instance_id,
        :flavor            => persister.flavors.lazy_find(instance.sys_type),
        :location          => _("unknown"),
        :name              => instance.server_name,
        :vendor            => "ibm",
        :connection_state  => "connected",
        :raw_power_state   => instance.status,
        :uid_ems           => instance.pvm_instance_id,
        :format            => instance.storage_type
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
      instance.volume_i_ds.to_a.each do |vol_id|
        volume = collector.volume(vol_id)

        persister.disks.build(
          :hardware        => ps_hw,
          :device_name     => volume.name,
          :device_type     => volume.disk_type,
          :controller_type => "ibm",
          :backing         => persister.cloud_volumes.find(vol_id),
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
        :vendor             => "ibm",
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
    collector.volumes.each do |volume_ref|
      vol = collector.volume(volume_ref.volume_id)

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

  def sshkeys
    collector.sshkeys.each do |tkey|
      tenant_key = {
        :creationDate => tkey.creation_date,
        :name         => tkey.name,
        :sshKey       => tkey.ssh_key,
      }

      # save the tenant instance
      persister.auth_key_pairs.build(:name => tenant_key[:name])
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
          :type        => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SAPProfile",
          :ems_ref     => value.profile_id,
          :name        => value.profile_id,
          :cpus        => value.cores,
          :memory      => value.memory&.gigabytes,
          :description => description
        )
      end
    end
  end

  def cloud_volume_types
    # get only the active storage
    collector.storage_types.storage_types_capacity.each do |v|
      persister.cloud_volume_types.build(
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolumeType",
        :ems_ref => v.storage_type,
        :name    => v.storage_type
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
end
