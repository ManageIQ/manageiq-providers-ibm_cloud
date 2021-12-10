describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager do
  context "ems" do
    it "does not support network update" do
      ems = FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud)
      expect(ems.supports?(:update)).to eq(false)
    end
  end

  context "singleton methods" do
    it "returns the expected value for the description method" do
      expect(described_class.description).to eq('IBM Power Systems Virtual Servers Network')
    end

    it "returns the expected value for the ems_type method" do
      expect(described_class.ems_type).to eq('ibm_cloud_power_virtual_servers_network')
    end

    it "returns the expected value for the hostname_required? method" do
      expect(described_class.hostname_required?).to eq(false)
    end

    it "returns the expected value for the display_name method" do
      expect(described_class.display_name).to eq('Network Manager')
      expect(described_class.display_name(2)).to eq('Network Managers')
    end
  end
end
