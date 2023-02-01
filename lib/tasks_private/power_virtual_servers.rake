namespace :vcr do
  namespace :power_virtual_servers do
    require "ibm_cloud_iam"
    require "ibm_cloud_resource_controller"
    require 'ibm_cloud_power'

    base_dir = ManageIQ::Providers::IbmCloud::Engine.root.join("spec")
    cass_dir = base_dir.join("vcr_cassettes/manageiq/providers/ibm_cloud")
    spec_dir = base_dir.join("models/manageiq/providers/ibm_cloud")

    resources = {
      :placement_groups => [
        IbmCloudPower::PlacementGroupCreate.new(
          "name"   => "test-placement-group-affinity",
          "policy" => "affinity"
        ),
        IbmCloudPower::PlacementGroupCreate.new(
          "name"   => "test-placement-group-anti-affinity",
          "policy" => "anti-affinity"
        )
      ],
      :spp_placement_groups => [
        IbmCloudPower::SPPPlacementGroupCreate.new(
          "name"   => "test_spppg",
          "policy" => "affinity"
        )
      ],
      :resource_pools       => [
        IbmCloudPower::SharedProcessorPoolCreate.new(
          "host_group"     => "s922",
          "name"           => "test_pool",
          "reserved_cores" => 1
        )
      ],
      :volumes => [
        IbmCloudPower::CreateDataVolume.new(
          "name"      => "test-volume-1GB-tier3-sharable",
          "size"      => 1,
          "disk_type" => "tier3",
          "shareable" => true
        ),
        IbmCloudPower::CreateDataVolume.new(
          "name"      => "test-volume-10GB-tier3-sharable",
          "size"      => 10,
          "disk_type" => "tier3",
          "shareable" => true
        ),
        IbmCloudPower::CreateDataVolume.new(
          "name"      => "test-volume-3GB-tier1-notsharable",
          "size"      => 3,
          "disk_type" => "tier1",
          "shareable" => false
        ),
        IbmCloudPower::CreateDataVolume.new(
          "name"      => "test-volume-15GB-tier1-notsharable",
          "size"      => 15,
          "disk_type" => "tier1",
          "shareable" => false
        )
      ],
      :networks => [
        IbmCloudPower::NetworkCreate.new(
          "name"  => "test-network-vlan",
          "type"  => "vlan",
          "cidr"  => "10.0.0.0/24",
          "jumbo" => false
        ),
        IbmCloudPower::NetworkCreate.new(
          "name"    => "test-network-vlan-jumbo",
          "type"    => "vlan",
          "cidr"    => "10.1.0.0/25",
          "gateway" => "10.1.0.16",
          "jumbo"   => true
        ),
        IbmCloudPower::NetworkCreate.new(
          "name" => "test-network-pub-vlan",
          "type" => "pub-vlan"
        ),
        IbmCloudPower::NetworkCreate.new(
          "name"        => "test-network-pub-vlan-dns",
          "type"        => "pub-vlan",
          "dns_servers" => "9.9.9.9"
        )
      ],
      :ssh_keys => [
        IbmCloudPower::SSHKey.new(
          "name"    => "test-ssh-key-no-comment",
          "ssh_key" => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCooZYGrwhEl5kCa0Pcdh2x0Xz/rOdru94tC8QI24bRFHPUAT88TKz48UciQE6/VaMdxxb9zrvA2eIU0/Td9lQU44B1LyEDLfILdxH1mHd2wehDM78V7804jvsxTMYXgNU8NEAJM+gyJ/K0rwvCReofL4jq/y4bbSEvVE+DxTnqzry2+SRCy0tEIfrHkJv2DMiB0oY680qEkZsAMZjE2JFrK8bN88kPhDb52x12llPMvUpppT4RBU3dDnweA50sxabV4SX0XVVJncw9nKh1EsUWrI4O7N3h8i8bLoiJvmGjIEpAQxE80ftvcbpJf0hPGsIr0BR+Qc+S6nBMdgpXj5RWlYS/ekxAVPe4xQsM01gMziwiX1RrcektajR8x/D3z28u7Nv1530b3rSqTMiydyXqcKMlTItqArpZVamo3UZ2CfuYRUdcpM+fbPCRsj0GH7pRxLqYag2klUIc9hZSgxQ85Yo5da+E7QjEvwxN5zxSyMy/ekRwsgWg6nDar9BFBV0="
        ),
        IbmCloudPower::SSHKey.new(
          "name"    => "test-ssh-key-with-comment",
          "ssh_key" => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvyVUxkBtMlmTemse/JcMhSxI4kIK4SzpMqQaUBaon9X30x62fjOik7lnqxqg/BXWVYI15nslSI/t5IbQGPGPBzR9RplBn/dx/Yxzcfgq5U5YBkvP9yXRYdp5f51z17a5+wWKI8Dka7vrLmv62thB83pjgiTsgFvqdSx7aYC4U3GFpboYHX/tQjrEpNBHRiRTeB9Ux/O+/gzGULlR0jd4denrWpng9Nn9n+N1e+tAkkUjUY0xTnodZfjnpYO/qhWSPwCglZeP9i9KdZFLCKuGTHkWbmQ1SnehRYEnLJ9lZRkhMsYq6uW1SNzMn16bGs3T7c+RkZUzs2JxFEjBIpEkq/uVDwVyIYd6dKQMp1cC8MEHQB2G6udrcvzwOJkb9xYqcJVpp0MzWApeBPwXUYJjCaxIHwF4TciYT0tleaoyZep9of0Wnrfv0BAtmY1f9obyEuRXKBFYmFlIvXripuueCL38KlQfVgmLuhnpSxXTVeiTZ8qTCxUkrJc6DZXh/z90= This is only a test!"
        ),
        IbmCloudPower::SSHKey.new(
          "name"    => "test-ssh-key-with-comment-line-breaks",
          "ssh_key" => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD06A0pk378CjUm3LR5O9BW03ZNKgQPsB0IdMzdM4pBOyiPMubmcvOvItDz0XmtRIBJxqxRZftJAq01ej2ZSq+Fk+cbGtGQngEVceaz2GnrGNLasyF0zKG5mLXkoQsm3tofRdCuLecBFPSVN31yuxeVxsNCYKunGtwNejC/GIroptuRANJYVAv3TaVl99MYHfhkJCEvomdimYWZmi4eEML9bAhqr7LBK7j6rcivcp6Z8LpIg4LUP1+jniV0dXbhycJhYaAvQtKySBwnx70LiShyy9R2P31LL8g19Dn75NK1kWNV5mRrWFdyX+GJ8lnalOyBN4irZ7T1wAnbJfd/Vfs9PtYz2iR9IFEKYaxpEgNB5FQQY3UoP5gPezfRstG0ohmJ2zYxHC6PYuYQUpgp6xhf7jEtC+WHjWtmN5/LJ74k13BVPlhrSAduYrZJ8mCS29b4gjBuIirW8nByaGh5HBToyjbxdlBqDJS0+qMeWPqwSlZGK/jTulNpmvAibX7CawM=\nYes, placing line breaks in SSH public\nkey comments doesn't break anything"
        ),
      ],
      :instances => [
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"   => "test-instance-aix-s922-shared-tier1",
          "image_id"      => "7300-00-01",
          "sys_type"      => "s922",
          "proc_type"     => "shared",
          "storage_type"  => "tier1",
          "processors"    => 0.25,
          "memory"        => 2,
          "key_pair_name" => "test-ssh-key-no-comment",
          "migratable"    => true,
          "pin_policy"    => "none",
          "networks"      => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-vlan"
            )
          ]
        ),
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"     => "test-instance-ibmi-s922-capped-tier1",
          "image_id"        => "IBMi-75-00-2984-1",
          "sys_type"        => "s922",
          "proc_type"       => "capped",
          "storage_type"    => "tier1",
          "processors"      => 0.25,
          "memory"          => 2,
          "key_pair_name"   => "test-ssh-key-with-comment",
          "migratable"      => false,
          "pin_policy"      => "soft",
          "placement_group" => "test-placement-group-affinity",
          "networks"        => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-vlan-jumbo"
            )
          ]
        ),
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"     => "test-instance-centos-e980-dedicated-tier3",
          "image_id"        => "CentOS-Stream-8",
          "sys_type"        => "e980",
          "proc_type"       => "dedicated",
          "storage_type"    => "tier3",
          "processors"      => 1,
          "memory"          => 4,
          "key_pair_name"   => "test-ssh-key-with-comment-line-breaks",
          "migratable"      => true,
          "pin_policy"      => "hard",
          "networks"        => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-pub-vlan"
            )
          ]
        ),
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"           => "test-instance-rhel-s922-shared-tier3",
          "image_id"              => "RHEL8-SP6",
          "sys_type"              => "s922",
          "proc_type"             => "shared",
          "storage_type"          => "tier3",
          "processors"            => 0.50,
          "memory"                => 2,
          "key_pair_name"         => "test-ssh-key-no-comment",
          "migratable"            => true,
          "pin_policy"            => "none",
          "shared_processor_pool" => "test_pool",
          "networks"              => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-pub-vlan-dns"
            )
          ]
        ),
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"     => "test-instance-sles-s922-shared-tier3",
          "image_id"        => "SLES15-SP4",
          "sys_type"        => "s922",
          "proc_type"       => "shared",
          "storage_type"    => "tier3",
          "processors"      => 0.75,
          "memory"          => 4,
          "key_pair_name"   => "test-ssh-key-no-comment",
          "migratable"      => true,
          "pin_policy"      => "none",
          "networks"        => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-vlan"
            ),
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-pub-vlan"
            )
          ]
        ),
        IbmCloudPower::PVMInstanceCreate.new(
          "server_name"     => "test-instance-rhcos-s922-shared-tier3",
          "image_id"        => "rhcos-4.8",
          "sys_type"        => "s922",
          "proc_type"       => "shared",
          "storage_type"    => "tier3",
          "processors"      => 1.25,
          "memory"          => 6,
          "key_pair_name"   => "test-ssh-key-no-comment",
          "migratable"      => true,
          "pin_policy"      => "none",
          "placement_group" => "test-placement-group-anti-affinity",
          "networks"        => [
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-vlan-jumbo"
            ),
            IbmCloudPower::PVMInstanceAddNetwork.new(
              "network_id" => "test-network-pub-vlan-dns"
            )
          ]
        )
      ],
      :snapshots => [
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-aix-s922-shared-tier1-snapshot-1",
          "description" => "server name: test-instance-aix-s922-shared-tier1"
        ),
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-ibmi-s922-capped-tier1-snapshot-1",
          "description" => "server name: test-instance-ibmi-s922-capped-tier1"
        ),
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-centos-e980-dedicated-tier3-snapshot-1",
          "description" => "server name: test-instance-centos-e980-dedicated-tier3"
        ),
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-rhel-s922-shared-tier3-snapshot-1",
          "description" => "server name: test-instance-rhel-s922-shared-tier3"
        ),
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-sles-s922-shared-tier3-snapshot-1",
          "description" => "server name: test-instance-sles-s922-shared-tier3"
        ),
        IbmCloudPower::SnapshotCreate.new(
          "name"        => "test-instance-rhcos-s922-shared-tier3-snapshot-1",
          "description" => "server name: test-instance-rhcos-s922-shared-tier3"
        ),
      ]
    }

    desc "Full re-record of PowerVS refresher VCR, including PowerVS resource setup and cleanup"
    task :rerecord => :environment do
      Rake::Task['vcr:power_virtual_servers:setup'].invoke
      Rake::Task['vcr:power_virtual_servers:record'].invoke
      Rake::Task['vcr:power_virtual_servers:cleanup'].invoke
    end

    desc "Setup PowerVS resources required for refresher spec"
    task :setup => :environment do
      # Setup connection to PowerVS service
      connection, tenant_id, cloud_instance_id = connect

      ## Templates (boot images)
      images_api = IbmCloudPower::PCloudImagesApi.new(connection)

      images = {}

      images_api.pcloud_cloudinstances_images_getall(cloud_instance_id).images.each do |image|
        images[image.name] = image
      end

      resources[:instances].each do |instance|
        image_name = instance.image_id
        instance.image_id = images[image_name].image_id
        puts "Found boot image '#{image_name}' (id: '#{instance.image_id}')"
      rescue NoMethodError
        raise "Cannot find boot image named '#{instance.image_id}'. Please manually import it to your PowerVS service instance."
      end

      ## Placement Groups
      placement_groups_api = IbmCloudPower::PCloudPlacementGroupsApi.new(connection)

      placement_groups = {}

      placement_groups_api.pcloud_placementgroups_getall(cloud_instance_id).placement_groups.each do |placement_group|
        placement_groups[placement_group.name] = placement_group
      end

      resources[:placement_groups].each do |placement_group|
        if placement_groups.include?(placement_group.name)
          puts "Placement group '#{placement_group.name}' already exists"
        else
          puts "Creating placement group '#{placement_group.name}'"
          created_placement_group = placement_groups_api.pcloud_placementgroups_post(
            cloud_instance_id,
            placement_group
          )
          placement_groups[placement_group.name] = created_placement_group
        end
      end

      ## Shared Processor Pool Placement Groups
      spp_pgs_api = IbmCloudPower::PCloudSPPPlacementGroupsApi.new(connection)

      spp_pgs = {}

      spp_pgs_api.pcloud_sppplacementgroups_getall(cloud_instance_id).spp_placement_groups.each do |spppg|
        spp_pgs[spppg.name] = spppg
      end

      resources[:spp_placement_groups].each do |placement_group|
        if spp_pgs.include?(placement_group.name)
          puts "SPP Placement group '#{placement_group.name}' already exists"
        else
          puts "Creating SPP placement group '#{placement_group.name}'"
          created_placement_group = spp_pgs_api.pcloud_sppplacementgroups_post(
            cloud_instance_id,
            placement_group
          )
          spp_pgs[placement_group.name] = created_placement_group
        end
      end

      ## Shared Processor Pools
      proc_pools_api = IbmCloudPower::PCloudSharedProcessorPoolsApi.new(connection)

      proc_pools = {}

      proc_pools_api.pcloud_sharedprocessorpools_getall(cloud_instance_id).shared_processor_pools.each do |proc_pool|
        proc_pools[proc_pool.name] = proc_pool
      end

      resources[:resource_pools].each do |resource_pool|
        if proc_pools.include?(resource_pool.name)
          puts "Shared processor pool '#{resource_pool.name}' already exists"
        else
          puts "Creating Shared processor pool '#{resource_pool.name}'"

          resource_pool.placement_group_id = spp_pgs[resources[:spp_placement_groups].first.name].id

          created_proc_pool = proc_pools_api.pcloud_sharedprocessorpools_post(
            cloud_instance_id,
            resource_pool
          )
          proc_pools[resource_pool.name] = created_proc_pool
        end
      end

      ## Volumes
      volumes_api = IbmCloudPower::PCloudVolumesApi.new(connection)

      volumes = {}

      volumes_api.pcloud_cloudinstances_volumes_getall(cloud_instance_id).volumes.each do |volume|
        volumes[volume.name] = volume
      end

      resources[:volumes].each do |volume|
        if volumes.include?(volume.name)
          puts "Block storage volume '#{volume.name}' already exists"
        else
          puts "Creating block storage volume '#{volume.name}'"
          created_volume = volumes_api.pcloud_cloudinstances_volumes_post(
            cloud_instance_id,
            volume
          )
          volumes[volume.name] = created_volume
        end
      end

      ## Networks
      networks_api = IbmCloudPower::PCloudNetworksApi.new(connection)

      networks = {}

      networks_api.pcloud_networks_getall(cloud_instance_id).networks.each do |network|
        networks[network.name] = network
      end

      resources[:networks].each do |network|
        if networks.include?(network.name)
          puts "Network '#{network.name}' already exists"
        else
          puts "Creating network '#{network.name}'"
          created_network = networks_api.pcloud_networks_post(
            cloud_instance_id,
            network
          )
          networks[network.name] = created_network
        end
      end

      ## SSH Keys
      tenants_ssh_keys_api = IbmCloudPower::PCloudTenantsSSHKeysApi.new(connection)

      ssh_keys = {}

      tenants_ssh_keys_api.pcloud_tenants_sshkeys_getall(tenant_id).ssh_keys.each do |ssh_key|
        ssh_keys[ssh_key.name] = ssh_key
      end

      resources[:ssh_keys].each do |ssh_key|
        if ssh_keys.include?(ssh_key.name)
          puts "SSH Key '#{ssh_key.name}' already exists"
        else
          puts "Creating SSH Key '#{ssh_key.name}'"
          created_ssh_key = tenants_ssh_keys_api.pcloud_tenants_sshkeys_post(
            tenant_id,
            ssh_key
          )
          ssh_keys[ssh_key.name] = created_ssh_key
        end
      end

      ## Instances
      pvm_instances_api = IbmCloudPower::PCloudPVMInstancesApi.new(connection)

      instances = {}

      pvm_instances_api.pcloud_pvminstances_getall(cloud_instance_id).pvm_instances.each do |instance|
        instances[instance.server_name] = instance
      end

      resources[:instances].each do |instance|
        if instances.include?(instance.server_name)
          puts "PVM Instance '#{instance.server_name}' already exists"
        else
          puts "Creating PVM Instance '#{instance.server_name}'"
          instance.networks.each do |network|
            network.network_id = networks[network.network_id].network_id
          end

          unless instance.placement_group.nil?
            instance.placement_group = placement_groups[instance.placement_group].id
          end

          unless instance.shared_processor_pool.nil?
            instance.shared_processor_pool = proc_pools[instance.shared_processor_pool].id
          end

          created_instance = pvm_instances_api.pcloud_pvminstances_post(
            cloud_instance_id,
            instance
          )[0]

          pvm_instance_id = created_instance.pvm_instance_id
          until created_instance.status == "ACTIVE"
            created_instance = pvm_instances_api.pcloud_pvminstances_get(
              cloud_instance_id,
              pvm_instance_id
            )
            sleep(10)
          end

          instances[instance.server_name] = created_instance
        end
      end

      ## Snapshots
      snapshots_api = IbmCloudPower::PCloudSnapshotsApi.new(connection)

      snapshots = {}

      snapshots_api.pcloud_cloudinstances_snapshots_getall(cloud_instance_id).snapshots.each do |snapshot|
        snapshots[snapshot.name] = snapshot
      end

      resources[:snapshots].each do |snapshot|
        if snapshots.include?(snapshot.name)
          puts "PVM Instance Snapshot '#{snapshot.name}' already exists"
        else
          puts "Creating PVM Instance Snapshot '#{snapshot.name}'"
          server_name = snapshot.description.match(/server name: (.*)/)[1]
          instance = instances[server_name]
          pvm_instances_api.pcloud_pvminstances_snapshots_post(
            cloud_instance_id,
            instance.pvm_instance_id,
            snapshot
          )
        end
      end
    end

    desc "Record new PowerVS refresh spec VCR cassette"
    task :record => :environment do
      # Run refresher spec
      # Delete existing VCR cassette
      cass_dir.glob("power_virtual_servers/cloud_manager/**/*.yml").each(&:delete)
      spec_file = spec_dir.join("power_virtual_servers/cloud_manager/refresher_spec.rb")
      `bundle exec rspec #{spec_file}`
    end

    desc "Clean up PowerVS resources required for refresher spec"
    task :cleanup => :environment do
      # Setup connection to PowerVS service
      connection, tenant_id, cloud_instance_id = connect

      ## Snapshots
      snapshot_names = resources[:snapshots].map(&:name)
      snapshots_api = IbmCloudPower::PCloudSnapshotsApi.new(connection)

      snapshots_api.pcloud_cloudinstances_snapshots_getall(cloud_instance_id).snapshots.each do |snapshot|
        next unless snapshot_names.include?(snapshot.name)

        puts "Deleting PVM Instance Snapshot '#{snapshot.name}' (id: '#{snapshot.snapshot_id}')"
        snapshots_api.pcloud_cloudinstances_snapshots_delete(cloud_instance_id, snapshot.snapshot_id)
      end

      ## Instances
      instance_names = resources[:instances].map(&:server_name)
      pvm_instances_api = IbmCloudPower::PCloudPVMInstancesApi.new(connection)
      pvm_instances_api.pcloud_pvminstances_getall(cloud_instance_id).pvm_instances.each do |instance|
        next unless instance_names.include?(instance.server_name)

        puts "Deleting PVM Instance '#{instance.server_name}' (id: '#{instance.pvm_instance_id}')"
        pvm_instances_api.pcloud_pvminstances_delete(
          cloud_instance_id,
          instance.pvm_instance_id,
          {:delete_data_volumes => true}
        )

        loop do
          puts "Waiting for '#{instance.server_name}' (id: '#{instance.pvm_instance_id}') to be deleted..."
          begin
            pvm_instances_api.pcloud_pvminstances_get(cloud_instance_id, instance.pvm_instance_id)
          rescue IbmCloudPower::ApiError
            break
          end
          sleep(5)
        end
      end

      ## Placement Groups
      placement_group_names = resources[:placement_groups].map(&:name)
      placement_groups_api = IbmCloudPower::PCloudPlacementGroupsApi.new(connection)
      placement_groups_api.pcloud_placementgroups_getall(cloud_instance_id).placement_groups.each do |placement_group|
        next unless placement_group_names.include?(placement_group.name)

        puts "Deleting Placement Group '#{placement_group.name}' (id: '#{placement_group.id}')"
        placement_groups_api.pcloud_placementgroups_delete(
          cloud_instance_id,
          placement_group.id
        )
      end

      ## Volumes
      volume_names = resources[:volumes].map(&:name)
      volumes_api = IbmCloudPower::PCloudVolumesApi.new(connection)
      volumes_api.pcloud_cloudinstances_volumes_getall(cloud_instance_id).volumes.each do |volume|
        next unless volume_names.include?(volume.name)

        puts "Deleting Block Storage Volume '#{volume.name}' (id: '#{volume.volume_id}')"
        volumes_api.pcloud_cloudinstances_volumes_delete(
          cloud_instance_id,
          volume.volume_id
        )
      end

      ## Networks
      network_names = resources[:networks].map(&:name)
      networks_api = IbmCloudPower::PCloudNetworksApi.new(connection)
      networks_api.pcloud_networks_getall(cloud_instance_id).networks.each do |network|
        next unless network_names.include?(network.name)

        puts "Deleting Network '#{network.name}' (id: '#{network.network_id}')"
        networks_api.pcloud_networks_delete(
          cloud_instance_id,
          network.network_id
        )
      end

      ## SSH Keys
      ssh_key_names = resources[:ssh_keys].map(&:name)
      tenants_ssh_keys_api = IbmCloudPower::PCloudTenantsSSHKeysApi.new(connection)
      tenants_ssh_keys_api.pcloud_tenants_sshkeys_getall(tenant_id).ssh_keys.each do |ssh_key|
        next unless ssh_key_names.include?(ssh_key.name)

        puts "Deleting SSH Key '#{ssh_key.name}'"
        tenants_ssh_keys_api.pcloud_tenants_sshkeys_delete(
          tenant_id,
          ssh_key.name
        )
      end
    end

    def connect
      # Prerequisites:
      # 1. Place IBM Cloud API key in secrets config
      # 2. Place PowerVS 'cloud_instance_id' (service guid) in secrets config

      # Setup IBM Cloud PowerVS connection
      begin
        api_key = YAML.load_file("config/secrets.yml").dig("test", "ibm_cloud_power", "api_key")
      rescue NoMethodError
        raise "IBM Cloud API key not found in secrets config file"
      end

      begin
        cloud_instance_id = YAML.load_file("config/secrets.yml").dig("test", "ibm_cloud_power", "cloud_instance_id")
      rescue NoMethodError
        raise "PowerVS 'cloud_instance_id' not found in secrets config file"
      end

      iam_token_api           = IbmCloudIam::TokenOperationsApi.new
      token                   = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)
      authenticator           = IbmCloudResourceController::Authenticators::BearerTokenAuthenticator.new(:bearer_token => token.access_token)
      resource_controller_api = IbmCloudResourceController::ResourceControllerV2.new(:authenticator => authenticator)
      power_iaas_service      = resource_controller_api.get_resource_instance(:id => cloud_instance_id).result

      _crn, _version, _cname, _ctype, _service_name, location, scope, _service_instance, _resource_type, _resource = power_iaas_service["crn"].split(":")
      region    = location.sub(/-*\d+$/, '')
      host      = ManageIQ::Providers::IbmCloud::PowerVirtualServers::Regions.regions[region][:hostname]
      tenant_id = scope.split('/')[1]

      connection                                  = IbmCloudPower::ApiClient.new
      connection.config.api_key                   = api_key
      connection.config.scheme                    = "https"
      connection.config.host                      = host
      connection.config.logger                    = $ibm_cloud_log
      connection.config.debugging                 = Settings.log.level_ibm_cloud == "debug"
      connection.default_headers["Crn"]           = power_iaas_service["crn"]
      connection.default_headers["Authorization"] = "#{token.token_type} #{token.access_token}"

      return connection, tenant_id, cloud_instance_id
    end
  end
end
