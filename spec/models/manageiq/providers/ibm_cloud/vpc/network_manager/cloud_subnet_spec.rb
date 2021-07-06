# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_network) do
    FactoryBot.create(:cloud_network_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager)
  end

  let(:cloud_subnet) do
    FactoryBot.create(:cloud_subnet_ibm_cloud_vpc,
                      :ext_management_system => ems.network_manager)
  end

  describe 'cloud subnet actions' do
    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
    end

    before { allow(ems.network_manager).to receive(:with_provider_connection).and_yield(connection) }

    context '#create_cloud_subnet' do
      it 'creates the cloud subnet' do
        expect(connection).to receive(:request).with(:create_subnet,
                                                     :subnet_prototype => {
                                                       :vpc             => {
                                                         :id => cloud_network.ems_ref
                                                       },
                                                       :name            => 'test',
                                                       :ipv4_cidr_block => '10.0.0.0/24'
                                                     })

        ems.network_manager.create_cloud_subnet({:cloud_network_id => cloud_network.id,
                                                 :name             => 'test',
                                                 :cidr             => '10.0.0.0/24'})
      end
    end

    context '#raw_delete_cloud_subnet' do
      it 'deletes the cloud subnet' do
        expect(connection).to receive(:request).with(:delete_subnet, :id => cloud_subnet.ems_ref)
        cloud_subnet.raw_delete_cloud_subnet
      end
    end
  end
end
