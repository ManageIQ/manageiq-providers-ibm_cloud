describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq('ibm_cloud_power_virtual_servers')
  end

  it ".description" do
    expect(described_class.description).to eq('IBM Power Systems Virtual Servers')
  end

  it "does not create orphaned network_manager" do
    ems = FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud)
    same_ems = ExtManagementSystem.find(ems.id)

    ems.destroy
    expect(ExtManagementSystem.count).to eq(0)

    same_ems.save!
    expect(ExtManagementSystem.count).to eq(0)
  end

  it "moves the network_manager to the same zone as the cloud_manager" do
    zone1 = FactoryBot.create(:zone)
    zone2 = FactoryBot.create(:zone)

    ems = FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :zone => zone1)
    expect(ems.network_manager.zone).to eq zone1
    expect(ems.network_manager.zone_id).to eq zone1.id

    ems.zone = zone2
    ems.save!
    ems.reload

    expect(ems.network_manager.zone).to eq zone2
    expect(ems.network_manager.zone_id).to eq zone2.id
  end

  describe "#catalog_types" do
    let(:ems) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }

    it "catalog_types" do
      expect(ems.catalog_types["IbmCloud::PowerVirtualServers"]).to eq "IBM PowerVS"
    end
  end
end
