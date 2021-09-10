# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  let(:ems) do
    api_key = Rails.application.secrets.ibm_cloud_vpc[:api_key]
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => api_key)
    end
  end

  it "tests the refresh" do
    2.times do
      VCR.use_cassette(described_class.name.underscore) do
        ems.refresh
      end

      ems.reload

      assert_ems_counts
      assert_specific_vm
      assert_specific_cloud_volume_type
      assert_specific_cloud_subnet
      assert_vm_labels
      assert_specific_floating_ip
    end
  end

  def assert_ems_counts
    # Cloud Manager
    expect(ems.vms.count).to eq(6)
    expect(ems.miq_templates.count).to eq(57)
    expect(ems.key_pairs.count).to eq(2)
    expect(ems.availability_zones.count).to eq(3)

    # Network Manager
    expect(ems.floating_ips.count).to eq(5)
    expect(ems.security_groups.count).to eq(2)
    expect(ems.security_groups.first.name).to eq('nebulizer-bobtail-hacked-yield-linseed-sandpit')
    expect(ems.cloud_networks.count).to eq(2)
    expect(ems.cloud_subnets.count).to eq(4)
    # Remove test. The cloud network ids are not predictable with more than 1 cloud network.
    # expect(ems.cloud_subnets.first.cloud_network_id).to eq(ems.cloud_networks[0].id)

    # Storage Manager
    expect(ems.cloud_volumes.count).to eq(15)
    expect(ems.cloud_volume_types.count).to eq(4)
  end

  def assert_specific_vm
    vm = ems.vms.find_by(:ems_ref => "0777_249ba858-a4eb-4f2c-ba6c-72254a781d0d")

    expect(vm.ipaddresses.count).to eq(1)
    expect(vm.availability_zone.name).to eq('us-east-3')
    expect(vm.cpu_total_cores).to eq(2)
    expect(vm.hardware.memory_mb).to eq(16_384)
    expect(vm.hardware.cpu_total_cores).to eq(2)
    expect(vm.hardware.cpu_sockets).to eq(2)
    expect(vm.hardware.bitness).to eq(64)
    expect(vm.operating_system[:product_name]).to eq('linux_redhat')
    expect(vm.flavor.name).to eq('mx2-2x16')
    expect(vm.raw_power_state).to eq('stopped')
    expect(vm.power_state).to eq('off')
    expect(vm.security_groups.count).to eq(1)

    ## linking key pairs to vms
    expect(vm.key_pairs.count).to eq(1)
    expect(vm.key_pairs.first.name).to eq('random_key_0')
    expect(vm.key_pairs.first.fingerprint).to eq('SHA256:xxxxxxx')
  end

  def assert_specific_floating_ip
    floating_ip = ems.floating_ips.find_by(:ems_ref => "r014-1892eee4-79ab-4d26-8efd-4c5759fc03fc")
    expect(floating_ip).to have_attributes(
      :type             => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::FloatingIp",
      :ems_ref          => "r014-1892eee4-79ab-4d26-8efd-4c5759fc03fc",
      :address          => "127.0.0.80",
      :fixed_ip_address => "127.0.0.5",
      :network_port     => ems.network_ports.find_by(:ems_ref => "0777-2f20fad9-dea8-4f28-ac7b-8d1b77a3230d"),
      :vm               => ems.vms.find_by(:ems_ref => "0777_a9ee9e6a-231a-4a3c-b9cb-fc83d25114a2"),
      :status           => "available"
    )
  end

  def assert_vm_labels
    vm = ems.vms.find_by(:ems_ref => "0777_f73e8687-3813-465f-99df-ba6e4ee8f289")

    expect(vm.labels.count).to eq(4)
  end

  def assert_specific_cloud_volume_type
    cvt = ems.cloud_volume_types.find_by(:ems_ref => 'general-purpose')

    expect(cvt.name).to eq('general-purpose')
    expect(cvt.description).to eq('tiered')
  end

  # Test the components of a cloud subnet.
  def assert_specific_cloud_subnet
    cloud_subnet = ems.cloud_subnets.find_by(:ems_ref => '0757-ef523a2f-5356-42ff-8a78-9325509465b9')

    # Test cloud_network relationship.
    cloud_network = ems.cloud_networks.find_by(:ems_ref => 'r014-0fa2acc6-2a41-4f2b-9c89-bcea07cdcbc3')
    expect(cloud_subnet.cloud_network_id).to eq(cloud_network.id)

    # Test availability_zone relationship.
    availability_zone = ems.availability_zones.find_by(:ems_ref => 'us-east-1')
    expect(cloud_subnet.availability_zone_id).to eq(availability_zone.id)

    # Test remaining fields.
    expect(cloud_subnet.cidr).to eq('127.0.0.0/24')
    expect(cloud_subnet.name).to eq('b-subneet-washington-dc-1')
    expect(cloud_subnet.ip_version).to eq('ipv4')
    expect(cloud_subnet.network_protocol).to eq('ipv4')
  end
end
