describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end

  describe 'validations' do
    it 'fails create with invalid parameters' do
      expect(subject.class.validate_create_key_pair(nil)).to eq(:available => false, :message => 'The Keypair is not connected to an active Provider')
    end

    it 'pass create with valid parameters' do
      expect(subject.class.validate_create_key_pair(ems)).to eq(:available => true, :message => nil)
    end
  end
end
