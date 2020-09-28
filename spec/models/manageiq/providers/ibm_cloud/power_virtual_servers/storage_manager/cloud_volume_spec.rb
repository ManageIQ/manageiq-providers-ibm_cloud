describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_storage, :provider_region => "us-south")
  end
  let(:StorageManager) { FactoryBot.create(:ems_IbmCloud_StorageManager, :parent_ems_id => ems_cloud.id) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume_IbmCloud, :ext_management_system => StorageManager ) }

  describe "cloud volume operations" do
    context "#delete_volume" do
      it "deletes the cloud volume" do
        def validate_delete_volume
          msg = validate_volume
          return {:available => msg[:available], :message => msg[:message]} unless msg[:available]
          if status == "in-use"
            return validation_failed("Delete Volume", "Can't delete volume that is in use.")
          end

          {:available => true, :message => nil}
        end
      end

      it "catches error from the provider" do
        def raw_delete_volume
          ext_management_system.with_provider_connection(:service => 'PowerIaas') do |power_iaas|
            power_iaas.delete_volume(ems_ref)
          end
        rescue => e
          _log.error("volume=[#{name}], error: #{e}")
        end
      end
    end
  end
end
