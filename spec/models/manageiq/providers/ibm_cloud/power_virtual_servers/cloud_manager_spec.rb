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
  end

  it "moves the network_manager to the same zone as the cloud_manager" do
    zone1 = FactoryBot.create(:zone)
    zone2 = FactoryBot.create(:zone)

    ems = FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :zone => zone1)
    expect(ems.network_manager.zone).to eq zone1

    ems.zone = zone2
    ems.save!
    ems.provider.save!
    ems.reload

    expect(ems.network_manager.zone).to eq zone2
  end

  describe "#catalog_types" do
    let(:ems) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }

    it "catalog_types" do
      expect(ems.catalog_types).to be_empty
    end
  end

  describe ".create_from_params" do
    let(:zone)           { FactoryBot.create(:zone) }
    let(:powervs_guid)   { SecureRandom.uuid }
    let(:params)         { {:zone => zone, :name => "IBM Cloud", :uid_ems => powervs_guid} }
    let(:authentication) { {"authtype" => "default", "auth_key" => "authkey"} }
    let!(:cloud_manager) { described_class.create_from_params(params, [], [authentication]) }

    it "creates cloud manager" do
      expect(cloud_manager.uid_ems).to eq(powervs_guid)
      expect(cloud_manager.name).to eq("IBM Cloud Power Virtual Servers")
    end

    it "creates child managers" do
      expect(cloud_manager.network_manager.name).to eq("Network-Manager of 'IBM Cloud Power Virtual Servers'")
      expect(cloud_manager.storage_manager.name).to eq("Storage-Manager of 'IBM Cloud Power Virtual Servers'")

      expect(cloud_manager.network_manager.zone).to eq(cloud_manager.zone)
      expect(cloud_manager.storage_manager.zone).to eq(cloud_manager.zone)
    end

    it "creates the parent provider" do
      expect(cloud_manager.provider).not_to be_nil
      expect(cloud_manager.provider.name).to eq("IBM Cloud")
      expect(cloud_manager.provider.power_virtual_servers_cloud_managers.first).to eq(cloud_manager)
    end

    it "delegates authentications to the parent provider" do
      expect(cloud_manager.provider.authentications.count).to eq(1)
    end
  end

  describe ".edit_with_params" do
    let(:zone)           { FactoryBot.create(:zone) }
    let(:new_zone)       { FactoryBot.create(:zone) }
    let(:cloud_manager)  { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :name => "IBM Cloud PowerVS", :zone => zone) }
    let(:params)         { {:zone => new_zone, :name => "IBM Cloud 2"} }
    let(:authentication) { {"authtype" => "default", "auth_key" => "authkey"} }

    before do
      cloud_manager.edit_with_params(params, [], [authentication])
      cloud_manager.reload
    end

    it "changing the name and zone updates the cloud manager" do
      expect(cloud_manager.name).to eq("IBM Cloud 2 Power Virtual Servers")
      expect(cloud_manager.zone).to eq(new_zone)
      expect(cloud_manager.provider).not_to be_nil
    end

    it "changing the name and zone updates the child managers" do
      expect(cloud_manager.network_manager.name).to eq("Network-Manager of 'IBM Cloud 2 Power Virtual Servers'")
      expect(cloud_manager.storage_manager.name).to eq("Storage-Manager of 'IBM Cloud 2 Power Virtual Servers'")

      expect(cloud_manager.network_manager.zone).to eq(new_zone)
      expect(cloud_manager.storage_manager.zone).to eq(new_zone)
    end

    it "chaning the name and zone changes the provider name" do
      expect(cloud_manager.provider.name).to eq("IBM Cloud 2")
      expect(cloud_manager.provider.zone).to eq(new_zone)
    end
  end

  context "#authentications" do
    let!(:cloud_manager) do
      FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :name => "IBM Cloud PowerVS", :zone => FactoryBot.create(:zone)) do |ems|
        ems.authentications << FactoryBot.create(:authentication, :authtype => "default", :status => "Valid", :userid => "abcd")
      end
    end

    it "delegates authentications to provider" do
      expect(cloud_manager.authentication_status).to eq("Valid")
      expect(cloud_manager.authentication_status_ok?).to be_truthy
    end
  end

  context "#destroy" do
    let(:zone)          { FactoryBot.create(:zone) }
    let(:cloud_manager) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :name => "IBM Cloud PowerVS", :zone => zone) }

    it "destroys child managers" do
      cloud_manager.destroy!
      expect(ExtManagementSystem.count).to eq(0)
    end

    it "destroys the parent provider" do
      cloud_manager.destroy!
      expect(Provider.count).to eq(0)
    end
  end
end
