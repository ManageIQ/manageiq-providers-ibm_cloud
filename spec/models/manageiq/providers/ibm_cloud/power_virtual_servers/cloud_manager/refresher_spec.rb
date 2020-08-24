describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_power_virtual_servers)
  end

  context "#refresh" do
    let(:ems) do
      uid_ems  = "473f85b4-c4ba-4425-b495-d26c77365c91"
      auth_key = Rails.application.secrets.ibmcvs.try(:[], :api_key) || "IBMCVS_API_KEY"

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
        assert_specific_vm
        assert_specific_template
        assert_specific_key_pair
        assert_specific_cloud_network
        assert_specific_cloud_subnet
        assert_specific_network_port
      end
    end

    it "refreshes the child network_manager" do
      2.times do
        full_refresh(ems.network_manager)
        ems.reload
        assert_table_counts
      end
    end

    it "refreshes the child storage_manager" do
      2.times do
        full_refresh(ems.storage_manager)
        ems.reload
        assert_table_counts
      end
    end

    def assert_table_counts
      expect(Vm.count).to eq(2)
      expect(OperatingSystem.count).to eq(2)
      expect(MiqTemplate.count).to eq(5)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to eq(1)
      expect(CloudVolume.count).to eq(3)
      expect(CloudNetwork.count).to eq(3)
      expect(CloudSubnet.count).to eq(3)
      expect(NetworkPort.count).to eq(3)
      expect(CloudSubnetNetworkPort.count).to eq(5)
    end

    def assert_ems_counts
      expect(ems.vms.count).to eq(2)
      expect(ems.miq_templates.count).to eq(5)
      expect(ems.operating_systems.count).to eq(2)
      expect(ems.key_pairs.count).to eq(1)
      expect(ems.network_manager.cloud_networks.count).to eq(3)
      expect(ems.network_manager.cloud_subnets.count).to eq(3)
      expect(ems.network_manager.network_ports.count).to eq(3)
    end

    def assert_specific_vm
      vm = ems.vms.find_by(:ems_ref => "7effc17f-f708-48f0-862d-4177fabf62fe")
      expect(vm).to have_attributes(
        :uid_ems          => "7effc17f-f708-48f0-862d-4177fabf62fe",
        :ems_ref          => "7effc17f-f708-48f0-862d-4177fabf62fe",
        :name             => "power-vsi-2",
        :description      => "IBM Cloud Server",
        :vendor           => "ibm",
        :power_state      => "on",
        :raw_power_state  => "ACTIVE",
        :connection_state => "connected",
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm"
      )

      expect(vm.hardware).to have_attributes(
        :cpu_sockets => 1,
        :memory_mb   => 2048
      )

      expect(vm.operating_system).to have_attributes(
        :product_name => "aix"
      )

      expect(vm.cloud_networks.pluck(:ems_ref))
        .to match_array(["339fc829-8c70-41dd-84c1-ca4b3a608b88-pub-vlan", "fe83beac-4c85-47a3-9aa5-4a7aecaca579-vlan"])

      expect(vm.cloud_subnets.pluck(:ems_ref))
        .to match_array(["339fc829-8c70-41dd-84c1-ca4b3a608b88", "fe83beac-4c85-47a3-9aa5-4a7aecaca579"])
      expect(vm.cloud_subnets.pluck(:name))
        .to match_array(["Admin Network", "public-192_168_129_72-29-VLAN_2037"])

      expect(vm.network_ports.pluck(:ems_ref))
        .to match_array(["c91ad01c-23e0-4602-b605-8f8c259e8150", "e86a8bde-d728-43a6-bc8f-6697ffd9a7a0"])
      expect(vm.network_ports.pluck(:mac_address))
        .to match_array(["fa:1f:a0:cd:36:20", "fa:16:3e:41:ce:4a"])
    end

    def assert_specific_template
      template = ems.miq_templates.find_by(:ems_ref => "b4ae82e3-51c2-49a3-9071-81f668232ed4")
      expect(template).to have_attributes(
        :uid_ems          => "b4ae82e3-51c2-49a3-9071-81f668232ed4",
        :ems_ref          => "b4ae82e3-51c2-49a3-9071-81f668232ed4",
        :name             => "7100-05-05",
        :description      => "System: aix, Architecture: ppc64, Endianess: big-endian",
        :vendor           => "ibm",
        :power_state      => "never",
        :raw_power_state  => "never",
        :connection_state => "connected",
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
      cloud_network = ems.network_manager.cloud_networks.find_by(:ems_ref => "339fc829-8c70-41dd-84c1-ca4b3a608b88-pub-vlan")
      expect(cloud_network).to have_attributes(
        :ems_ref => "339fc829-8c70-41dd-84c1-ca4b3a608b88-pub-vlan",
        :name    => "public-192_168_129_72-29-VLAN_2037-pub-vlan",
        :cidr    => "",
        :status  => "active",
        :enabled => true,
        :type    => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudNetwork"
      )
    end

    def assert_specific_cloud_subnet
      cloud_subnet = ems.network_manager.cloud_subnets.find_by(:ems_ref => "339fc829-8c70-41dd-84c1-ca4b3a608b88")
      expect(cloud_subnet).to have_attributes(
        :ems_ref          => "339fc829-8c70-41dd-84c1-ca4b3a608b88",
        :name             => "public-192_168_129_72-29-VLAN_2037",
        :cidr             => "192.168.129.72/29",
        :status           => "active",
        :gateway          => "192.168.129.73",
        :network_protocol => "IPv4",
        :dns_nameservers  => ["9.9.9.9"],
        :extra_attributes => {:ip_version=>"4"},
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet"
      )
    end

    def assert_specific_network_port
      network_port = ems.network_manager.network_ports.find_by(:ems_ref => "c91ad01c-23e0-4602-b605-8f8c259e8150")
      expect(network_port).to have_attributes(
        :ems_ref     => "c91ad01c-23e0-4602-b605-8f8c259e8150",
        :name        => "c91ad01c-23e0-4602-b605-8f8c259e8150",
        :mac_address => "fa:1f:a0:cd:36:20",
        :status      => "ACTIVE",
        :device_ref  => "7effc17f-f708-48f0-862d-4177fabf62fe",
      )

      expect(network_port.cloud_subnets.count).to eq(2)
      expect(network_port.cloud_subnet_network_ports.pluck(:address))
        .to match_array(["192.168.129.76", "52.117.38.76"])
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
