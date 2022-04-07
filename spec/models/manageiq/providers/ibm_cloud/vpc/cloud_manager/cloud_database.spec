describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabase do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east")
  end

  let(:cloud_database) do
    FactoryBot.create(:cloud_database_ibm_cloud_vpc, :ext_management_system => ems)
  end

  describe 'cloud database actions' do
    let(:connection) do
      double("ManageIQ::Providers::IbmCloud::CloudTools")
    end

    let(:resource_controller) do
      double("ManageIQ::Providers::IbmCloud::CloudTools::ResourceController::Controller")
    end

    before { allow(ems).to receive(:with_provider_connection).and_yield(connection) }

    context '#delete_cloud_database' do
      it 'deletes the cloud database' do
        allow(connection).to receive_message_chain(:resource, :controller).and_return(resource_controller)
        expect(resource_controller).to receive(:request).with(:delete_resource_instance, :id => cloud_database.ems_ref)
        cloud_database.delete_cloud_database
      end
    end
  end
end
