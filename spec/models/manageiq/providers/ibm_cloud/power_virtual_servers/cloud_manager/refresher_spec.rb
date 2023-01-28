describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_power_virtual_servers)
  end

  context "#refresh" do
    let(:ems) do
      uid_ems  = Rails.application.secrets.ibm_cloud_power[:cloud_instance_id]
      auth_key = Rails.application.secrets.ibm_cloud_power[:api_key]

      FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :uid_ems => uid_ems).tap do |ems|
        ems.authentications << FactoryBot.create(:authentication, :auth_key => auth_key)
      end
    end

    it "full refresh" do
      2.times do
        full_refresh(ems)
        ems.reload

        assert_table_counts
        assert_ems_counts
        assert_specific_flavor
        assert_specific_vm
        assert_specific_template
        assert_specific_key_pair
        assert_specific_cloud_network
        assert_specific_cloud_subnet
        assert_specific_network_port
        assert_specific_cloud_volume
        assert_specific_placement_group
        assert_volume_type_attribs
        assert_cloud_manager
      end
    end

    it "refreshes the child network_manager" do
      2.times do
        full_refresh(ems.network_manager)
        ems.reload
        assert_table_counts
        assert_specific_flavor
      end
    end

    it "refreshes the child storage_manager" do
      2.times do
        full_refresh(ems.storage_manager)
        ems.reload
        assert_table_counts
        assert_specific_flavor
      end
    end

    it "refreshes the cloud manager then network manager" do
      2.times do
        full_refresh(ems)
        ems.reload
        assert_table_counts
        assert_specific_flavor
        assert_cloud_manager

        full_refresh(ems.network_manager)
        assert_table_counts
        assert_specific_flavor
      end
    end

    def assert_table_counts
      expect(CloudVolume.count).to eq(10)
      expect(CloudNetwork.count).to eq(4)
      expect(CloudSubnet.count).to eq(4)
      expect(CloudSubnetNetworkPort.count).to eq(12)
      expect(Flavor.count).to eq(56)
      expect(MiqTemplate.count).to eq(6)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to be > 1
      expect(NetworkPort.count).to eq(8)
      expect(OperatingSystem.count).to eq(12)
      expect(PlacementGroup.count).to eq(2)
      expect(Vm.count).to eq(6)
    end

    def assert_ems_counts
      expect(ems.key_pairs.count).to be > 1
      expect(ems.miq_templates.count).to eq(6)
      expect(ems.network_manager.cloud_networks.count).to eq(4)
      expect(ems.network_manager.cloud_subnets.count).to eq(4)
      expect(ems.network_manager.network_ports.count).to eq(8)
      expect(ems.operating_systems.count).to eq(12)
      expect(ems.placement_groups.count).to eq(2)
      expect(ems.storage_manager.cloud_volume_types.count).to eq(2)
      expect(ems.storage_manager.cloud_volumes.count).to eq(10)
      expect(ems.vms.count).to eq(6)
    end

    def assert_cloud_manager
      expect(ems).to have_attributes(
        :provider_region => "mon01"
      )
    end

    def assert_specific_flavor
      flavor_ems_ref = "s922"
      flavor = ems.flavors.find_by(:ems_ref => flavor_ems_ref)

      expect(flavor).to have_attributes(
        :name => flavor_ems_ref,
        :type => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType"
      )
    end

    def assert_specific_vm
      instance_name = "test-instance-rhel-s922-shared-tier3"
      vm = ems.vms.find_by(:name => instance_name)
      expect(vm).to have_attributes(
        :location           => "unknown",
        :name               => instance_name,
        :description        => "PVM Instance",
        :vendor             => "ibm_power_vs",
        :power_state        => "on",
        :placement_group_id => nil,
        :raw_power_state    => "ACTIVE",
        :connection_state   => "connected",
        :type               => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm"
      )
      expect(vm.ems_created_on).to be_a(ActiveSupport::TimeWithZone)

      expect(vm.hardware).to have_attributes(
        :cpu_sockets     => 1,
        :cpu_total_cores => 1,
        :memory_mb       => 2048,
        :cpu_type        => "ppc64le",
        :guest_os        => "linux_redhat",
        :bitness         => 64
      )

      expect(vm.operating_system).to have_attributes(
        :product_name => "linux_redhat"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'entitled_processors' }).to have_attributes(
        :value        => "0.5"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'processor_type' }).to have_attributes(
        :value        => "shared"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'pin_policy' }).to have_attributes(
        :value        => "none"
      )

      expect(vm.snapshots.first).to have_attributes(
        :type              => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Snapshot",
        :name              => "test-instance-rhel-s922-shared-tier3-snapshot-1",
        :vm_or_template_id => vm.id
      )

      expect(vm.snapshots.first.total_size).to be > 0
    end

    def assert_specific_template
      template_name = "7300-00-01"
      template = ems.miq_templates.find_by(:name => template_name)
      expect(template).to have_attributes(
        :name             => template_name,
        :description      => "stock",
        :vendor           => "ibm_power_vs",
        :power_state      => "never",
        :raw_power_state  => "never",
        :connection_state => nil,
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template"
      )
    end

    def assert_specific_key_pair
      key_pair = ems.key_pairs.find_by(:name => "test-ssh-key-with-comment")
      expect(key_pair).to have_attributes(
        :name => "test-ssh-key-with-comment",
        :type => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair"
      )
    end

    def assert_specific_cloud_network
      # the network name is network::id + network::type
      # currently not comapring cidr as it is empty in the db
      subnet_name = "test-network-vlan-jumbo" # PowerVS only has subnets, but MIQ requires a parent network
      cloud_network = ems.network_manager.cloud_networks.find_by(:name => "#{subnet_name}-vlan")
      expect(cloud_network).to have_attributes(
        :name    => "#{subnet_name}-vlan",
        :status  => "active",
        :enabled => true,
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudNetwork"
      )
    end

    def assert_specific_cloud_subnet
      subnet_name = "test-network-vlan-jumbo"
      cloud_subnet = ems.network_manager.cloud_subnets.find_by(:name => subnet_name)
      expect(cloud_subnet.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_subnet).to have_attributes(
        :name             => subnet_name,
        :status           => "active",
        :network_protocol => "IPv4",
        :extra_attributes => {:ip_version => "4", :network_type => "vlan"},
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet"
      )
    end

    def assert_specific_network_port
      network_port = ems.network_manager.network_ports.first
      expect(network_port).to have_attributes(
        :status      => "ACTIVE",
        :device_type => "VmOrTemplate"
      )

      expect(network_port.cloud_subnets.count).to eq(1)
    end

    def assert_specific_cloud_volume
      cloud_volume_name = "test-volume-1GB-tier3-sharable"
      cloud_volume = ems.storage_manager.cloud_volumes.find_by(:name => cloud_volume_name)
      expect(cloud_volume).to have_attributes(
        :name             => cloud_volume_name,
        :volume_type      => "tier3",
        :size             => 1&.gigabytes,
        :multi_attachment => true
      )
    end

    def assert_specific_placement_group
      placement_group_name = "test-placement-group-anti-affinity"
      placement_group = ems.placement_groups.find_by(:name => placement_group_name)
      expect(placement_group).to have_attributes(
        :name   => placement_group_name,
        :policy => "anti-affinity",
        :type   => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::PlacementGroup"
      )
    end

    def assert_volume_type_attribs
      voltypes = ems.storage_manager.cloud_volume_types
      voltypes.each do |vtype|
        expect(vtype[:name].length).to be > 0
        expect(vtype[:description].length).to be > 0
      end
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
