describe ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq('ibm_cloud_object_storage')
  end

  it ".description" do
    expect(described_class.description).to eq('IBM Cloud Object Storage')
  end

  describe "#catalog_types" do
    let(:ems) { FactoryBot.create(:ems_ibm_cloud_object_storage_object) }

    it "catalog_types" do
      expect(ems.catalog_types).to be_empty
    end
  end
end
