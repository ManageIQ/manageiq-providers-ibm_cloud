# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_network) do
    FactoryBot.create(:cloud_network_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager)
  end

  describe 'cloud network actions' do
    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools")
    end

    let(:vpc) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    before { allow(ems.network_manager).to receive(:with_provider_connection).and_yield(connection) }
    before { allow(connection).to receive(:vpc).with(:region => ems.provider_region).and_return(vpc) }

    context '#create_cloud_network' do
      it 'creates the cloud network' do
        expect(vpc).to receive(:request).with(:create_vpc, :name => 'test')
        ems.network_manager.create_cloud_network({:name => 'test'})
      end
    end

    context '#raw_delete_cloud_network' do
      before { NotificationType.seed }

      it 'deletes the cloud network' do
        expect(vpc).to receive(:request).with(:delete_vpc, :id => cloud_network.ems_ref)
        cloud_network.raw_delete_cloud_network
      end

      it 'with cloud subnets' do
        exception = IBMCloudSdkCore::ApiException.new(
          :code                  => 409,
          :error                 => "Delete VPC failed: VPC still contains subnets",
          :transaction_id        => "1234",
          :global_transaction_id => "5678"
        )
        expect(vpc).to receive(:request)
          .with(:delete_vpc, :id => cloud_network.ems_ref)
          .and_raise(exception)

        expect { cloud_network.raw_delete_cloud_network }.to raise_error(IBMCloudSdkCore::ApiException)
        expect(Notification.count).to eq(1)
        expect(Notification.first)
          .to have_attributes(:options => {:error_message => exception.to_s,
                                           :subject       => "[#{cloud_network.name}]"})
      end
    end
  end
end
