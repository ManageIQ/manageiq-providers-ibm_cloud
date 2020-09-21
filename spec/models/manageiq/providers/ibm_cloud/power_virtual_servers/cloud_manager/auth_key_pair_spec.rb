describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end

  describe 'key pair create and delete' do
    it 'creates new key pair' do
      service = double
      allow(ExtManagementSystem).to receive(:find).with(ems.id).and_return(ems)
      allow(ems).to receive(:connect).with(:service => 'PowerIaas').and_return(service)
      expect(service).to receive(:create_key_pair).with("new-name", "public-key").and_return({"name" => "new-name"})
      described_class.create_key_pair(ems.id, :name => "new-name", :public_key => "public-key")
    end

    it 'deletes existing key pair' do
      service = double
      subject.name = 'key1'
      subject.resource = ems
      allow(ems).to receive(:connect).with(:service => 'PowerIaas').and_return(service)
      expect(service).to receive(:delete_key_pair).with('key1')
      subject.delete_key_pair
    end
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
