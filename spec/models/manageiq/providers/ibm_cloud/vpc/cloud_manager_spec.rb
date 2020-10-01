describe ManageIQ::Providers::IbmCloud::VPC::CloudManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq('ibm_vpc')
  end

  it ".ems_description" do
    expect(described_class.description).to eq('IBM Virtual Private Cloud')
  end

  it "tests the verify credentials logic" do
    expect(validate('IBMCVS_API_KEY')).to eq(true)
  end

  it "does not create orphaned network_manager" do
    ems = FactoryBot.create(:ems_ibm_cloud_vpc)
    same_ems = ExtManagementSystem.find(ems.id)

    expect(ExtManagementSystem.count).to eq(3)
    ems.destroy
    expect(ExtManagementSystem.count).to eq(0)

    same_ems.save!
    expect(ExtManagementSystem.count).to eq(0)
  end

  it "moves the network_manager to the same zone as the cloud_manager" do
    zone1 = FactoryBot.create(:zone)
    zone2 = FactoryBot.create(:zone)

    ems = FactoryBot.create(:ems_ibm_cloud_vpc, :zone => zone1)
    expect(ems.network_manager.zone).to eq zone1
    expect(ems.network_manager.zone_id).to eq zone1.id

    ems.zone = zone2
    ems.save!
    ems.reload

    expect(ems.network_manager.zone).to eq zone2
    expect(ems.network_manager.zone_id).to eq zone2.id
  end

  it "tests the connect logic" do
    zone1 = FactoryBot.create(:zone)
    ems = FactoryBot.create(:ems_ibm_cloud_vpc, :zone => zone1, :provider_region => "us-east")
    ems.authentications << FactoryBot.create(:authentication, :auth_key => "IBMCVS_API_KEY")
    VCR.use_cassette(described_class.name.underscore) do
      expect(!!ems.connect).to eq(true)
    end
    ems.destroy
  end

  def validate(auth_key)
    VCR.use_cassette(described_class.name.underscore) do
      described_class.verify_credentials("authentications" => {"default" => {"auth_key" => auth_key}})
    end
  end
end
