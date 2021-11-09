describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end

  describe 'validations' do
    it 'supports create' do
      expect(ems.class_by_ems("AuthKeyPair").supports?(:create)).to be_truthy
    end
  end
end
