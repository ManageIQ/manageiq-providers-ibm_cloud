# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => 'IBM_CLOUD_VPC_API_KEY')
    end
  end

  let(:cloud_network) do
    FactoryBot.create(:cloud_network_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager,
                      :name                  => 'test',
                      :ems_ref               => 'test_id')
  end

  describe '#raw_delete_cloud_network' do
    before { NotificationType.seed }

    let(:connection) do
      vpc = double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
      allow(vpc).to receive(:logger).and_return(Logger.new(nil))
      allow(vpc).to receive_messages(:cloudtools => nil, :region => nil, :version => nil, :request => nil)
      vpc
    end

    it 'deletes the cloud network' do
      expect(cloud_network).to receive(:with_provider_connection).and_yield(connection)
      expect(connection).to receive(:request).with(:delete_vpc, :id => cloud_network.ems_ref)
      cloud_network.raw_delete_cloud_network(:options => {})
    end
  end
end
