describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_power_virtual_servers)
  end

  context "#refresh" do
    let(:ems) do
      uid_ems  = "3ea904f1-67df-4ae0-960f-e13ffa469f12"
      auth_key = Rails.application.secrets.ibm_cloud_power[:api_key]

      FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :uid_ems => uid_ems, :provider_region => "us-south").tap do |ems|
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

        full_refresh(ems.network_manager)
        assert_table_counts
        assert_specific_flavor
      end
    end

    def assert_table_counts
      expect(Flavor.count).to eq(51)
      expect(Vm.count).to eq(3)
      expect(OperatingSystem.count).to eq(9)
      expect(MiqTemplate.count).to eq(6)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to eq(57)
      expect(CloudVolume.count).to eq(5)
      expect(CloudNetwork.count).to eq(3)
      expect(CloudSubnet.count).to eq(3)
      expect(NetworkPort.count).to eq(5)
      expect(CloudSubnetNetworkPort.count).to eq(5)
    end

    def assert_ems_counts
      expect(ems.vms.count).to eq(3)
      expect(ems.miq_templates.count).to eq(6)
      expect(ems.operating_systems.count).to eq(9)
      expect(ems.key_pairs.count).to eq(57)
      expect(ems.network_manager.cloud_networks.count).to eq(3)
      expect(ems.network_manager.cloud_subnets.count).to eq(3)
      expect(ems.network_manager.network_ports.count).to eq(5)
      expect(ems.storage_manager.cloud_volumes.count).to eq(5)
      expect(ems.storage_manager.cloud_volume_types.count).to eq(2)
    end

    def assert_specific_flavor
      flavor = ems.flavors.find_by(:ems_ref => "s922")

      expect(flavor).to have_attributes(
        :ems_ref => "s922",
        :name    => "s922",
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType"
      )
    end

    def assert_specific_vm
      vm = ems.vms.find_by(:ems_ref => "b898b0cd-463b-4b05-90d3-b98f73234e8f")
      expect(vm).to have_attributes(
        :uid_ems          => "b898b0cd-463b-4b05-90d3-b98f73234e8f",
        :ems_ref          => "b898b0cd-463b-4b05-90d3-b98f73234e8f",
        :location         => "unknown",
        :name             => "rdr-powervs-aix",
        :description      => "PVM Instance",
        :vendor           => "ibm_cloud",
        :power_state      => "on",
        :raw_power_state  => "ACTIVE",
        :connection_state => "connected",
        :format           => "tier3",
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm"
      )

      expect(vm.hardware).to have_attributes(
        :cpu_sockets     => 1,
        :cpu_total_cores => 1,
        :memory_mb       => 2048,
        :guest_os        => 'unix_aix',
        :cpu_type        => 'ppc64',
        :bitness         => 64
      )

      expect(vm.operating_system).to have_attributes(
        :product_name => "unix_aix",
        :version      => "AIX 7.1, 7100-05-05-1939"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'entitled_processors' }).to have_attributes(
        :value        => "0.25"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'processor_type' }).to have_attributes(
        :value        => "shared"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'pin_policy' }).to have_attributes(
        :value        => "none"
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'placement_group' }).to have_attributes(
        :value        => nil
      )

      expect(vm.cloud_networks.pluck(:ems_ref))
        .to match_array(["2126f163-ab11-471a-95a5-7003f23ae9e2-pub-vlan", "caf12e74-8b75-46db-8bd0-4aded9fcfbc5-vlan"])

      expect(vm.cloud_subnets.pluck(:ems_ref))
        .to match_array(["2126f163-ab11-471a-95a5-7003f23ae9e2", "caf12e74-8b75-46db-8bd0-4aded9fcfbc5"])
      expect(vm.cloud_subnets.pluck(:name))
        .to match_array(["private-network-1", "public-192_168_172_72-29-VLAN_2037"])

      expect(vm.network_ports.pluck(:ems_ref))
        .to match_array(["7c276396-b967-4228-846c-c7b1b6b17858", "97156faf-2d0a-4932-b862-1048652ec511"])
      expect(vm.network_ports.pluck(:mac_address))
        .to match_array(["fa:d9:90:05:76:20", "fa:d9:90:05:76:21"])
    end

    def assert_specific_template
      template = ems.miq_templates.find_by(:ems_ref => "0dbe9ca3-a65a-432e-adf4-71115b479414")
      expect(template).to have_attributes(
        :uid_ems          => "0dbe9ca3-a65a-432e-adf4-71115b479414",
        :ems_ref          => "0dbe9ca3-a65a-432e-adf4-71115b479414",
        :name             => "7100-05-05",
        :description      => "stock",
        :vendor           => "ibm_cloud",
        :power_state      => "never",
        :raw_power_state  => "never",
        :connection_state => nil,
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template"
      )
    end

    def assert_specific_key_pair
      key_pair = ems.key_pairs.find_by(:name => "beta")
      expect(key_pair).to have_attributes(
        :name => "beta",
        :type => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair"
      )
    end

    def assert_specific_cloud_network
      cloud_network = ems.network_manager.cloud_networks.find_by(:ems_ref => "2126f163-ab11-471a-95a5-7003f23ae9e2-pub-vlan")
      expect(cloud_network).to have_attributes(
        :ems_ref => "2126f163-ab11-471a-95a5-7003f23ae9e2-pub-vlan",
        :name    => "public-192_168_172_72-29-VLAN_2037-pub-vlan",
        :cidr    => "",
        :status  => "active",
        :enabled => true,
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudNetwork"
      )
    end

    def assert_specific_cloud_subnet
      cloud_subnet = ems.network_manager.cloud_subnets.find_by(:ems_ref => "2126f163-ab11-471a-95a5-7003f23ae9e2")
      expect(cloud_subnet.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_subnet).to have_attributes(
        :ems_ref          => "2126f163-ab11-471a-95a5-7003f23ae9e2",
        :name             => "public-192_168_172_72-29-VLAN_2037",
        :cidr             => "127.0.0.72/29",
        :status           => "active",
        :gateway          => "127.0.0.73",
        :network_protocol => "IPv4",
        :dns_nameservers  => ["127.0.0.9"],
        :extra_attributes => {:ip_version => "4", :network_type => "pub-vlan"},
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet"
      )
    end

    def assert_specific_network_port
      network_port = ems.network_manager.network_ports.find_by(:ems_ref => "97156faf-2d0a-4932-b862-1048652ec511")
      expect(network_port).to have_attributes(
        :ems_ref     => "97156faf-2d0a-4932-b862-1048652ec511",
        :name        => "97156faf-2d0a-4932-b862-1048652ec511",
        :mac_address => "fa:d9:90:05:76:21",
        :status      => "DOWN",
        :device_ref  => "b898b0cd-463b-4b05-90d3-b98f73234e8f"
      )

      expect(network_port.cloud_subnets.count).to eq(1)
      expect(network_port.cloud_subnet_network_ports.pluck(:address))
        .to match_array(["127.0.0.145"])
    end

    def assert_specific_cloud_volume
      cloud_volume = ems.storage_manager.cloud_volumes.find_by(:ems_ref => "332a6789-e493-4664-981f-e3d90c902ac4")
      expect(cloud_volume.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_volume.creation_time.to_s).to eql("2021-07-07 01:55:28 UTC")
      expect(cloud_volume).to have_attributes(
        :ems_ref          => "332a6789-e493-4664-981f-e3d90c902ac4",
        :name             => "jaytest1",
        :status           => "available",
        :bootable         => false,
        :description      => "IBM Cloud Block-Storage Volume",
        :volume_type      => "tier1",
        :size             => 10.gigabyte,
        :multi_attachment => true
      )
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
