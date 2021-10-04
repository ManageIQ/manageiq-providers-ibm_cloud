describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end

  describe 'validations' do
    it 'ems supports auth_key_pair_create' do
      expect(ems.supports?(:auth_key_pair_create)).to eq(true)
    end
  end
end
