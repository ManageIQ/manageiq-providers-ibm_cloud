# frozen_string_literal: true

# rubocop:disable Style/MethodCallWithArgsParentheses # Guidance does not conform to preferred expect formatting.
describe ManageIQ::Providers::IbmCloud::VPC::CloudManager, :vcr do
  # Defined in config/secrets.yml of the manageiq repo.
  let(:api_key) { Rails.application.secrets.ibm_cloud_vpc[:api_key] }

  it ".ems_type" do
    expect(described_class.ems_type).to eq('ibm_vpc')
  end

  it ".ems_description" do
    expect(described_class.description).to eq('IBM Cloud VPC')
  end

  it "verifies regions options" do
    expect(described_class.provider_region_options.count).to eq(8)
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

  context "#connect" do
    let(:ems) do
      FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
        ems.authentications << FactoryBot.create(:authentication, :auth_key => api_key)
      end
    end

    it "tests the connect logic" do
      expect(ems.verify_credentials).to be_truthy
    end
  end

  context ".verify_credentials" do
    it "verifies the connection" do
      described_class.verify_credentials("authentications" => {"default" => {"auth_key" => api_key}})
    end
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses
