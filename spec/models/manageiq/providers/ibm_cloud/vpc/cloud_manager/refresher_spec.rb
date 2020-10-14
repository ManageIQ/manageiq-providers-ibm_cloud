describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  let(:ems) do
    api_key = Rails.application.secrets.ibmcvs.try(:[], :api_key) || "IBMCVS_API_KEY"
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
    end
  end

  def assert_ems_counts
    # Cloud Manager
    expect(ems.vms.count).to eq(4)
    expect(ems.miq_templates.count).to eq(46)
    expect(ems.key_pairs.count).to eq(1)
    expect(ems.availability_zones.count).to eq(3)

    # Network Manager
    expect(ems.floating_ips.count).to eq(2)
    expect(ems.security_groups.count).to eq(1)
    expect(ems.security_groups.first.name).to eq('nebulizer-bobtail-hacked-yield-linseed-sandpit')
    expect(ems.cloud_networks.count).to eq(1)
    expect(ems.cloud_subnets.count).to eq(1)
    expect(ems.cloud_subnets.first.cloud_network_id).to eq(ems.cloud_networks[0].id)

    # Storage Manager
    expect(ems.cloud_volumes.count).to eq(11)
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
    expect(vm.operating_system[:product_name]).to eq('red-7-amd64')
    expect(vm.flavor.name).to eq('mx2-2x16')
    expect(vm.raw_power_state).to eq('running')
    expect(vm.power_state).to eq('on')
    expect(vm.security_groups.count).to eq(1)

    ## linking key pairs to vms
    expect(vm.key_pairs.count).to eq(1)
    expect(vm.key_pairs.first.name).to eq('cloudforms')
    expect(vm.key_pairs.first.fingerprint).to eq('SHA256:w6v2HXjIgk/2yxiVs8cvnt1AxyxVVDsVRcWlNRoyCRE')
  end
end
