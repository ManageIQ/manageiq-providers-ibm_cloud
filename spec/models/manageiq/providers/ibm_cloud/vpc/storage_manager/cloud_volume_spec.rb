describe ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolume do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_volume) do
    FactoryBot.create(:cloud_volume_ibm_cloud_vpc,
                      :ext_management_system => ems.storage_manager)
  end

  describe 'cloud volume actions' do
    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    before { allow(ems.storage_manager).to receive(:with_provider_connection).and_yield(connection) }

    context '#raw_delete_volume' do
      it 'deletes the cloud volume' do
        expect(connection).to receive(:request).with(:delete_volume, :id => cloud_volume.ems_ref)
        cloud_volume.raw_delete_volume
      end
    end
  end
end
