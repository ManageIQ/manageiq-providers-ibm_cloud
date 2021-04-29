describe ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_object_storage)
  end
end
