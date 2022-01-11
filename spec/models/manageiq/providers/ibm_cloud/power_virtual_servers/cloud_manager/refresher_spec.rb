describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_power_virtual_servers)
  end

  context "#refresh" do
    let(:ems) do
      uid_ems  = "8fa27c40-827c-4568-8813-79b398e9cd27"
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
      expect(Flavor.count).to eq(56)
      expect(Vm.count).to eq(1)
      expect(OperatingSystem.count).to eq(2)
      expect(MiqTemplate.count).to eq(1)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to eq(50)
      expect(CloudVolume.count).to eq(2)
      expect(CloudNetwork.count).to eq(2)
      expect(CloudSubnet.count).to eq(2)
      expect(NetworkPort.count).to eq(2)
      expect(CloudSubnetNetworkPort.count).to eq(3)
    end

    def assert_ems_counts
      expect(ems.vms.count).to eq(1)
      expect(ems.miq_templates.count).to eq(1)
      expect(ems.operating_systems.count).to eq(2)
      expect(ems.key_pairs.count).to eq(50)
      expect(ems.network_manager.cloud_networks.count).to eq(2)
      expect(ems.network_manager.cloud_subnets.count).to eq(2)
      expect(ems.network_manager.network_ports.count).to eq(2)
      expect(ems.storage_manager.cloud_volumes.count).to eq(2)
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
      vm = ems.vms.find_by(:ems_ref => "039d63f7-c658-499f-8c15-02a146899917")
      expect(vm).to have_attributes(
        :uid_ems          => "039d63f7-c658-499f-8c15-02a146899917",
        :ems_ref          => "039d63f7-c658-499f-8c15-02a146899917",
        :location         => "unknown",
        :name             => "rdr-miq-test-vm",
        :description      => "PVM Instance",
        :vendor           => "ibm_cloud",
        :power_state      => "on",
        :raw_power_state  => "ACTIVE",
        :connection_state => "connected",
        :format           => "tier3",
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm"
      )
      expect(vm.ems_created_on).to be_a(ActiveSupport::TimeWithZone)
      expect(vm.ems_created_on.to_s).to eql("2022-01-06 20:54:24 UTC")

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
        :version      => "AIX 7.2, 7200-05-01-2038"
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
        .to match_array(["ebc60295-6b51-435a-92db-21a925832cdf-vlan", "4b30b3df-4b2d-4567-ac22-16330998bf2c-pub-vlan"])

      expect(vm.cloud_subnets.pluck(:ems_ref))
        .to match_array(["ebc60295-6b51-435a-92db-21a925832cdf", "4b30b3df-4b2d-4567-ac22-16330998bf2c"])
      expect(vm.cloud_subnets.pluck(:name))
        .to match_array(["hiro-test-network", "public-192_168_165_88-29-VLAN_2039"])

      expect(vm.network_ports.pluck(:ems_ref))
        .to match_array(["9cfb491a-a736-4663-8ed4-841b613d162a", "2121a828-51d8-43ad-bacb-29be8e04fd59"])
      expect(vm.network_ports.pluck(:mac_address))
        .to match_array(["fa:16:3e:ca:2a:ab", "fa:58:59:da:78:20"])

      expect(vm.snapshots.count).to eq(2)
      expect(vm.snapshots.pluck(:ems_ref))
        .to match_array(["b145643f-2228-4f3b-bfa8-aeade1333ac4", "f14012a9-7d3d-494b-9bc9-cfe85633bed1"])
    end

    def assert_specific_template
      template = ems.miq_templates.find_by(:ems_ref => "7eb025ee-10cd-4668-a930-8ac4f17a3245")
      expect(template).to have_attributes(
        :uid_ems          => "7eb025ee-10cd-4668-a930-8ac4f17a3245",
        :ems_ref          => "7eb025ee-10cd-4668-a930-8ac4f17a3245",
        :name             => "7200-05-01",
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
      cloud_network = ems.network_manager.cloud_networks.find_by(:ems_ref => "4b30b3df-4b2d-4567-ac22-16330998bf2c-pub-vlan")
      expect(cloud_network).to have_attributes(
        :ems_ref => "4b30b3df-4b2d-4567-ac22-16330998bf2c-pub-vlan",
        :name    => "public-192_168_165_88-29-VLAN_2039-pub-vlan",
        :cidr    => "",
        :status  => "active",
        :enabled => true,
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudNetwork"
      )
    end

    def assert_specific_cloud_subnet
      cloud_subnet = ems.network_manager.cloud_subnets.find_by(:ems_ref => "ebc60295-6b51-435a-92db-21a925832cdf")
      expect(cloud_subnet.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_subnet).to have_attributes(
        :ems_ref          => "ebc60295-6b51-435a-92db-21a925832cdf",
        :name             => "hiro-test-network",
        :cidr             => "127.0.0.0/24",
        :status           => "active",
        :gateway          => "127.0.0.1",
        :network_protocol => "IPv4",
        :dns_nameservers  => ["127.0.0.1"],
        :extra_attributes => {:ip_version => "4", :network_type => "vlan"},
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet"
      )
    end

    def assert_specific_network_port
      network_port = ems.network_manager.network_ports.find_by(:ems_ref => "2121a828-51d8-43ad-bacb-29be8e04fd59")
      expect(network_port).to have_attributes(
        :ems_ref     => "2121a828-51d8-43ad-bacb-29be8e04fd59",
        :name        => "2121a828-51d8-43ad-bacb-29be8e04fd59",
        :mac_address => "fa:58:59:da:78:20",
        :status      => "ACTIVE",
        :device_ref  => "039d63f7-c658-499f-8c15-02a146899917"
      )

      expect(network_port.cloud_subnets.count).to eq(2)
      expect(network_port.cloud_subnet_network_ports.pluck(:address))
        .to match_array(["127.0.0.222", "127.0.0.94"])
    end

    def assert_specific_cloud_volume
      cloud_volume = ems.storage_manager.cloud_volumes.find_by(:ems_ref => "c962bf00-527b-4f53-87b7-6bd0daac4de5")
      expect(cloud_volume.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_volume.creation_time.to_s).to eql("2022-01-06 20:53:44 UTC")
      expect(cloud_volume).to have_attributes(
        :ems_ref          => "c962bf00-527b-4f53-87b7-6bd0daac4de5",
        :name             => "hiro-test-vol",
        :status           => "in-use",
        :bootable         => false,
        :description      => "IBM Cloud Block-Storage Volume",
        :volume_type      => "tier3",
        :size             => 1.gigabyte,
        :multi_attachment => false
      )
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
