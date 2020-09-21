describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_vpc)
  end

  context "#refresh" do
    let(:ems) do
      auth_key = Rails.application.secrets.ibmcvs.try(:[], :api_key) || "IBMCVS_API_KEY"

      FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-south").tap do |ems|
        ems.authentications << FactoryBot.create(:authentication, :auth_key => auth_key)
      end
    end

    it "full refresh" do
      2.times do
        full_refresh(ems)
        ems.reload

        assert_table_counts
        assert_ems_counts
      end
    end

    def assert_table_counts
      expect(Vm.count).to eq(2)
      expect(OperatingSystem.count).to eq(2)
      expect(MiqTemplate.count).to eq(5)
      expect(ManageIQ::Providers::CloudManager::AuthKeyPair.count).to eq(8)
      expect(CloudVolume.count).to eq(4)
      expect(CloudNetwork.count).to eq(3)
      expect(CloudSubnet.count).to eq(3)
      expect(NetworkPort.count).to eq(3)
      expect(CloudSubnetNetworkPort.count).to eq(5)
    end

    def assert_ems_counts
      expect(ems.vms.count).to eq(2)
      expect(ems.miq_templates.count).to eq(5)
      expect(ems.operating_systems.count).to eq(2)
      expect(ems.key_pairs.count).to eq(8)
      expect(ems.network_manager.cloud_networks.count).to eq(3)
      expect(ems.network_manager.cloud_subnets.count).to eq(3)
      expect(ems.network_manager.network_ports.count).to eq(3)
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
