# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_subnet) do
    FactoryBot.create(:cloud_subnet_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager)
  end

  describe '#raw_delete_cloud_subnet' do
    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    it 'deletes the cloud subnet' do
      expect(cloud_subnet).to receive(:with_provider_connection).and_yield(connection)
      expect(connection).to receive(:request).with(:delete_subnet, :id => cloud_subnet.ems_ref)
      cloud_subnet.raw_delete_cloud_subnet
    end
  end
end
