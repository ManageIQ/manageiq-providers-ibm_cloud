describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_power_virtual_servers)
  end

  @testname = "provision-vm"

  specs = YAML.load_file(File.join(__dir__, "#{@testname}.yml"))
  specs['resources'].each do |key, _value|
    case key['type']
    when 'ibm_pi_instance'
      let(:instance_data) { key['instances'][0]['attributes'] }
    when 'ibm_pi_image'
      let(:instance_image) { key['instances'][0]['attributes'] }
    when 'ibm_pi_network'
      let(:public_network) { key['instances'][0]['attributes'] } if key['name'] == 'public_network'
      let(:power_network) { key['instances'][0]['attributes'] } if key['name'] == 'power_network'
    when 'ibm_pi_volume'
      let(:volume_data) { key['instances'][0]['attributes'] }
    end
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
      expect(Flavor.count).to eq(56)
      expect(Vm.count).to eq(3)
      expect(OperatingSystem.count).to eq(7)
      expect(MiqTemplate.count).to eq(4)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to be > 1
      expect(CloudVolume.count).to eq(6)
      expect(CloudNetwork.count).to eq(2)
      expect(CloudSubnet.count).to eq(2)
      expect(NetworkPort.count).to eq(6)
      expect(CloudSubnetNetworkPort.count).to eq(9)
    end

    def assert_ems_counts
      expect(ems.vms.count).to eq(3)
      expect(ems.miq_templates.count).to eq(4)
      expect(ems.operating_systems.count).to eq(7)
      expect(ems.key_pairs.count).to be > 1
      expect(ems.network_manager.cloud_networks.count).to eq(2)
      expect(ems.network_manager.cloud_subnets.count).to eq(2)
      expect(ems.network_manager.network_ports.count).to eq(6)
      expect(ems.storage_manager.cloud_volumes.count).to eq(6)
      expect(ems.storage_manager.cloud_volume_types.count).to eq(2)
    end

    def assert_cloud_manager
      region = Rails.application.secrets.ibm_cloud_power[:ibmcloud_region]
      expect(ems).to have_attributes(
        :provider_region => "#{region}01"
      )
    end

    def assert_specific_flavor
      flavor = ems.flavors.find_by(:ems_ref => "s922")

      expect(flavor).to have_attributes(
        :name => "s922",
        :type => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::SystemType"
      )
    end

    def assert_specific_vm
      vm = ems.vms.find_by(:ems_ref => instance_data['instance_id'])
      expect(vm).to have_attributes(
        :uid_ems          => instance_data['instance_id'],
        :ems_ref          => instance_data['instance_id'],
        :location         => "unknown",
        :name             => instance_data['pi_instance_name'],
        :description      => "PVM Instance",
        :vendor           => "ibm_power_vs",
        :power_state      => "on",
        :raw_power_state  => "ACTIVE",
        :connection_state => "connected",
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm"
      )
      expect(vm.ems_created_on).to be_a(ActiveSupport::TimeWithZone)
      expect(vm.ems_created_on.to_s).to eql("2022-02-11 01:05:12 UTC")

      expect(vm.hardware).to have_attributes(
        :cpu_sockets     => 1,
        :cpu_total_cores => 1,
        :memory_mb       => instance_data['pi_memory'] * 1024,
        :cpu_type        => instance_image['architecture'],
        :guest_os        => OperatingSystem.normalize_os_name(instance_image['operatingsystem'] || 'unknown'),
        :bitness         => 64
      )

      expect(vm.operating_system).to have_attributes(
        :product_name => OperatingSystem.normalize_os_name(instance_image['operatingsystem'] || 'unknown')
      )

      expect(vm.advanced_settings.find { |setting| setting['name'] == 'entitled_processors' }).to have_attributes(
        :value        => "1.0"
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

      expect(vm.snapshots.count).to eq(1)
      expect(vm.snapshots.first).to have_attributes(
        :name              => 'test-snapshot-1',
        :vm_or_template_id => vm.id
      )
      expect(vm.snapshots.first.total_size).to be > 0
    end

    def assert_specific_template
      template = ems.miq_templates.find_by(:ems_ref => instance_image["id"])
      expect(template).to have_attributes(
        :uid_ems          => instance_image["id"],
        :ems_ref          => instance_image["id"],
        :name             => instance_image["pi_image_name"],
        :description      => instance_image["image_type"],
        :vendor           => "ibm_power_vs",
        :power_state      => "never",
        :raw_power_state  => "never",
        :connection_state => nil,
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template"
      )
    end

    def assert_specific_key_pair
      key_pair = ems.key_pairs.find_by(:name => instance_data['pi_key_pair_name'])
      expect(key_pair).to have_attributes(
        :name => instance_data['pi_key_pair_name'],
        :type => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair"
      )
    end

    def assert_specific_cloud_network
      # the network name is network::id + network::type
      # currently not comapring cidr as it is empty in the db
      netname = public_network["name"]
      netid   = public_network["id"]
      nettype = public_network["type"]
      cloud_network = ems.network_manager.cloud_networks.find_by(:ems_ref => "#{netid}-#{nettype}")
      expect(cloud_network).to have_attributes(
        :name    => "#{netname}-#{nettype}",
        :status  => 'active',
        :enabled => true,
        :type    => 'ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudNetwork'
      )
    end

    def assert_specific_cloud_subnet
      cloud_subnet = ems.network_manager.cloud_subnets.find_by(:ems_ref => public_network["id"])
      expect(cloud_subnet.availability_zone&.ems_ref).to eq(ems.uid_ems)
      expect(cloud_subnet).to have_attributes(
        :ems_ref          => public_network["id"],
        :name             => public_network["name"],
        :status           => "active",
        :network_protocol => "IPv4",
        :extra_attributes => {:ip_version => "4", :network_type => public_network["type"]},
        :type             => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet"
      )
    end

    def assert_specific_network_port
      network_data = instance_data["pi_network"].find { |obj| obj["network_name"] == public_network["name"] }
      network_port = ems.network_manager.network_ports.find_by(:mac_address => network_data["mac_address"])
      expect(network_port).to have_attributes(
        :status      => "ACTIVE"
      )

      expect(network_port.cloud_subnets.count).to eq(2)
    end

    def assert_specific_cloud_volume
      cloud_volume = ems.storage_manager.cloud_volumes.find_by(:ems_ref => instance_data["pi_volume_ids"][0])
      expect(cloud_volume).to have_attributes(
        :ems_ref     => volume_data['id'].partition('/').last,
        :name        => volume_data['pi_volume_name'],
        :status      => volume_data['volume_status'],
        :volume_type => volume_data['pi_volume_type']
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
