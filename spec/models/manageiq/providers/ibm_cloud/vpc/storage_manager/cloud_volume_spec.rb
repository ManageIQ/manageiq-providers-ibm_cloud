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
      double("ManageIQ::Providers::IbmCloud::CloudTools")
    end

    let(:vpc) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    before { allow(ems.storage_manager).to receive(:with_provider_connection).and_yield(connection) }
    before { allow(connection).to receive(:vpc).with(:region => ems.provider_region).and_return(vpc) }

    context '#raw_create_volume' do
      it 'creates a cloud volume' do
        expect(vpc).to receive(:request).with(:create_volume,
                                                     :volume_prototype => {
                                                       :profile  => {
                                                         :name => '5iops-tier'
                                                       },
                                                       :zone     => {
                                                         :name => 'test-zone'
                                                       },
                                                       :name     => 'test',
                                                       :capacity => 10
                                                     })

        cloud_volume.class.raw_create_volume(ems.storage_manager, {:volume_type          => '5iops-tier',
                                                                   :availability_zone_id => 'test-zone',
                                                                   :name                 => 'test',
                                                                   :size                 => '10'})
      end

      it 'creates a custom profile cloud volume' do
        expect(vpc).to receive(:request).with(:create_volume,
                                                     :volume_prototype => {
                                                       :profile  => {
                                                         :name => 'custom'
                                                       },
                                                       :zone     => {
                                                         :name => 'test-zone'
                                                       },
                                                       :name     => 'test',
                                                       :capacity => 10,
                                                       :iops     => 100
                                                     })

        cloud_volume.class.raw_create_volume(ems.storage_manager, {:volume_type          => 'custom',
                                                                   :availability_zone_id => 'test-zone',
                                                                   :name                 => 'test',
                                                                   :size                 => '10',
                                                                   :iops                 => '100'})
      end
    end

    context '#raw_delete_volume' do
      it 'deletes the cloud volume' do
        expect(vpc).to receive(:request).with(:delete_volume, :id => cloud_volume.ems_ref)
        cloud_volume.raw_delete_volume
      end
    end
  end
end
