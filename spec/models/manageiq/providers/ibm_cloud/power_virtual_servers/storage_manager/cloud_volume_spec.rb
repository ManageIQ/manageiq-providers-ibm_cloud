describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume do
  let(:ems_cloud) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }
  let(:ems_storage) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_storage, :parent_ems_id => ems_cloud.id) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume_ibm_cloud_power_virtual_servers, :ext_management_system => ems_storage ) }

  describe "#validate_delete_volume" do
  context "status is in-use" do
    let(:status) { "in-use" }

    it "validates unavailable" do
    end
  end

  context "status is available"
    let(:status) { "available" }

    it "validates available" do
    end
  end
end
