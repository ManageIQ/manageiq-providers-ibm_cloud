describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end
  let(:StorageManager) { FactoryBot.create(:ems_IbmCloud_StorageManager, :parent_ems_id => ems_cloud.id) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume_IbmCloud, :ext_management_system => StorageManager ) }

  describe "cloud volume operations" do
    context "#delete_volume" do
      it "deletes the cloud volume" do
        stubbed_responses = {
          :ec2 => {
            :delete_volume => {}
          }
        }

        with_aws_stubbed(stubbed_responses) do
          expect(cloud_volume.delete_volume).to be_truthy
        end
      end

      it "catches error from the provider" do
        stubbed_responses = {
          :ec2 => {
            :delete_volume => "UnauthorizedOperation"
          }
        }

        with_aws_stubbed(stubbed_responses) do
          expect do
            cloud_volume.delete_volume
          end.to raise_error(MiqException::MiqVolumeDeleteError)
        end
      end
    end
  end
end