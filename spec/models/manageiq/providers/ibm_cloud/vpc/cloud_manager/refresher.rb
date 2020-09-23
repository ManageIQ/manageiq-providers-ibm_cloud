describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  it "tests the refresh" do
    zone1 = FactoryBot.create(:zone)
    ems = FactoryBot.create(:ems_ibm_cloud_vpc, :zone => zone1, :provider_region => "us-east")
    ems.authentications << FactoryBot.create(:authentication, :auth_key => "IBMCVS_API_KEY")
    VCR.use_cassette(described_class.name.underscore) do
      ems.refresh
    end
    ems.reload
    expect(ems.vms.count).to eq(2)
    expect(ems.miq_templates.count).to eq(39)
    expect(ems.key_pairs.count).to eq(1)
    expect(ems.availability_zones.count).to eq(3)

    vm = ems.vms[1]
    expect(vm.availability_zone.name).to eq('us-east-3')
    expect(vm.cpu_total_cores).to eq(2)
    expect(vm.hardware.memory_mb).to eq(16 * 1024)
    expect(vm.hardware.cpu_total_cores).to eq(2)
    expect(vm.hardware.cpu_sockets).to eq(2)
    expect(vm.operating_system[:product_name]).to eq('red-7-amd64')
    expect(vm.operating_system[:vm_or_template_id]).to eq(vm.id)
    expect(vm.flavor.name).to eq('mx2-2x16')

    ## netowkr manager stuff ##
    expect(ems.security_groups.count).to eq(1)
    expect(ems.security_groups[0].name).to eq('nebulizer-bobtail-hacked-yield-linseed-sandpit')
    expect(ems.cloud_networks.count).to eq(1)
    expect(ems.cloud_subnets.count).to eq(1)
    expect(ems.cloud_subnets[0].cloud_network_id).to eq(ems.cloud_networks[0].id)

    ## linking key pairs to vms
    expect(vm.key_pairs.count).to eq(1)
    expect(vm.key_pairs[0].name).to eq('cloudforms')
    expect(vm.key_pairs[0].fingerprint).to eq('SHA256:w6v2HXjIgk/2yxiVs8cvnt1AxyxVVDsVRcWlNRoyCRE')

    ems.destroy
  end
end
