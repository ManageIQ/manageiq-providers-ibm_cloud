describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq("ibm_cloud_power_virtual_servers")
  end

  let(:ems) do
    uid_ems  = VcrSecrets.ibm_cloud_power.cloud_instance_id
    auth_key = VcrSecrets.ibm_cloud_power.api_key

    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :uid_ems => uid_ems).tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => auth_key)
    end
  end

  it "verify credentials" do
    VCR.use_cassette(described_class.name.underscore) do
      ems.verify_credentials
    end
  end
end
