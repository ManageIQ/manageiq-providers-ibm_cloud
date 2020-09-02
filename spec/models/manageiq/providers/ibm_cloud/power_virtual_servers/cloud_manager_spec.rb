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
      expect(ems.catalog_types).to be_empty
    end
  end

  describe ".create_from_params" do
    let(:zone)         { FactoryBot.create(:zone) }
    let(:powervs_guid) { SecureRandom.uuid }

    it "creates cloud manager" do
      params = {:zone => zone, :name => "IBM Cloud PowerVS", :uid_ems => powervs_guid}
      authentication = {"authtype" => "default", "auth_key" => "authkey"}

      cloud_manager = described_class.create_from_params(params, [], [authentication])

      expect(cloud_manager.uid_ems).to eq(powervs_guid)
      expect(cloud_manager.name).to eq("IBM Cloud PowerVS")
    end

    it "creates child managers" do
      params = {:zone => zone, :name => "IBM Cloud PowerVS", :uid_ems => powervs_guid}
      authentication = {"authtype" => "default", "auth_key" => "authkey"}

      cloud_manager = described_class.create_from_params(params, [], [authentication])

      expect(cloud_manager.network_manager.name).to eq("Network-Manager of 'IBM Cloud PowerVS'")
      expect(cloud_manager.storage_manager.name).to eq("Storage-Manager of 'IBM Cloud PowerVS'")

      expect(cloud_manager.network_manager.zone).to eq(cloud_manager.zone)
      expect(cloud_manager.storage_manager.zone).to eq(cloud_manager.zone)
    end
  end

  describe ".edit_with_params" do
    let(:zone)          { FactoryBot.build(:zone) }
    let(:new_zone)      { FactoryBot.build(:zone) }
    let(:cloud_manager) { FactoryBot.build(:ems_ibm_cloud_power_virtual_servers_cloud, :name => "IBM Cloud PowerVS", :zone => zone) }

    it "changing the name and zone updates the cloud manager" do
      params = {:zone => new_zone, :name => "IBM Cloud PowerVS 2"}
      authentication = {"authtype" => "default", "auth_key" => "authkey"}

      cloud_manager.edit_with_params(params, [], [authentication])

      cloud_manager.reload

      expect(cloud_manager.name).to eq("IBM Cloud PowerVS 2")
      expect(cloud_manager.zone).to eq(new_zone)
    end

    it "changing the name and zone updates the child managers" do
      params = {:zone => new_zone, :name => "IBM Cloud PowerVS 2"}
      authentication = {"authtype" => "default", "auth_key" => "authkey"}

      cloud_manager.edit_with_params(params, [], [authentication])

      cloud_manager.reload

      expect(cloud_manager.network_manager.name).to eq("Network-Manager of 'IBM Cloud PowerVS 2'")
      expect(cloud_manager.storage_manager.name).to eq("Storage-Manager of 'IBM Cloud PowerVS 2'")

      expect(cloud_manager.network_manager.zone).to eq(new_zone)
      expect(cloud_manager.storage_manager.zone).to eq(new_zone)
    end
  end
end
