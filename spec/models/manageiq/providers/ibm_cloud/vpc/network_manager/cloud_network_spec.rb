# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_network) do
    FactoryBot.create(:cloud_network_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager)
  end

  describe '#raw_delete_cloud_network' do
    before { NotificationType.seed }

    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    it 'deletes the cloud network' do
      expect(cloud_network).to receive(:with_provider_connection).and_yield(connection)
      expect(connection).to receive(:request).with(:delete_vpc, :id => cloud_network.ems_ref)
      cloud_network.raw_delete_cloud_network
    end

    it 'with cloud subnets' do
      exception = IBMCloudSdkCore::ApiException.new(
        :code                  => 409,
        :error                 => "Delete VPC failed: VPC still contains subnets",
        :transaction_id        => "1234",
        :global_transaction_id => "5678"
      )
      expect(cloud_network).to receive(:with_provider_connection).and_yield(connection)
      expect(connection).to receive(:request)
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
