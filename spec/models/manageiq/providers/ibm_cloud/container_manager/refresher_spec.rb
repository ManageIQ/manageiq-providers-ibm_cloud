describe ManageIQ::Providers::IbmCloud::ContainerManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:iks)
  end

  let(:zone) { EvmSpecHelper.create_guid_miq_server_zone.last }
  let!(:ems) { FactoryBot.create(:ems_ibm_cloud_iks_with_vcr_authentication, :zone => zone) }

  it "will perform a full refresh" do
    2.times do
      VCR.use_cassette(described_class.name.underscore) { EmsRefresh.refresh(ems) }

      ems.reload

      assert_table_counts
    end
  end

  def assert_table_counts
    expect(ems.container_projects.count).to         eq(7)
    expect(ems.container_nodes.count).to            eq(9)
    expect(ems.container_services.count).to         eq(12)
    expect(ems.container_groups.count).to           eq(49)
    expect(ems.containers.count).to                 eq(91)
    expect(ems.container_images.count).to           eq(22)
    expect(ems.container_image_registries.count).to eq(3)
  end
end
