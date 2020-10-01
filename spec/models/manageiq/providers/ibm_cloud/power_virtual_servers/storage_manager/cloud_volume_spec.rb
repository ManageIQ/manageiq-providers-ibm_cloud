describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume do

  let(:ems_cloud) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }
  let(:ems_storage) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_storage, :parent_ems_id => ems_cloud.id) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume_ibm_cloud_power_virtual_servers, :ext_management_system => ems_storage ) }


  context "#validate_delete_volume" do
    it "status is in-use" do
      expect(cloud_volume).to receive(:status).and_return("in-use")
      validation = cloud_volume.validate_delete_volume
      expect(validation[:available]).to be false
    end

    it "status is available" do
      expect(cloud_volume).to receive(:status).and_return("available")
      validation = cloud_volume.validate_delete_volume
      expect(validation[:available]).to be true
    end

    it "ems is missing" do
      expect(cloud_volume).to receive(:ext_management_system).and_return(nil)
      validation = cloud_volume.validate_delete_volume
      expect(validation[:available]).to be false
    end
  end
end
