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

    before do
      allow(ems).to receive(:with_provider_connection).and_yield(connection)
      allow(connection).to receive_message_chain(:resource, :controller).and_return(resource_controller)
    end

    context '#create_cloud_database' do
      let(:resource_group) { FactoryBot.create(:resource_group, :name => "test123", :ems_ref => "rg-1", :ext_management_system => ems) }
      it 'creates the cloud database' do
        expect(resource_controller).to receive(:request).with(:create_resource_instance,
                                                              :name             => "test-db",
                                                              :target           => ems.provider_region,
                                                              :resource_group   => resource_group.ems_ref,
                                                              :resource_plan_id => "databases-for-postgresql-standard")
        cloud_database.class.raw_create_cloud_database(ems, {:name                => "test-db",
                                                             :resource_group_name => resource_group.name,
                                                             :database            => "postgresql"})
      end
    end

    context '#delete_cloud_database' do
      it 'deletes the cloud database' do
        expect(resource_controller).to receive(:request).with(:delete_resource_instance, :id => cloud_database.ems_ref)
        cloud_database.delete_cloud_database
      end
    end

    context '#update_cloud_database' do
      it 'updates the cloud database' do
        expect(resource_controller).to receive(:request).with(:update_resource_instance, :id => cloud_database.ems_ref, :name => "test-db-new")
        cloud_database.update_cloud_database({:name => "test-db-new"})
      end
    end
  end
end
