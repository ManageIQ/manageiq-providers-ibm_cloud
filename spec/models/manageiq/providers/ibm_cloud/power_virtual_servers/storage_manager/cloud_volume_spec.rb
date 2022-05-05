describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume do
  let(:ems_cloud) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }
  let(:ems_storage) do
    FactoryBot.create(
      :ems_ibm_cloud_power_virtual_servers_storage,
      :parent_manager => ems_cloud
    )
  end
  let(:cloud_volume) do
    FactoryBot.create(
      :cloud_volume_ibm_cloud_power_virtual_servers,
      :ext_management_system => ems_storage,
      :status                => status,
      :multi_attachment      => multi_attachment
    )
  end
  let(:status) { "available" }
  let(:multi_attachment) { false }

  describe "#supports?(:delete)" do
    context "when available" do
      it "validation passes" do
        expect(cloud_volume.supports?(:delete)).to be_truthy
      end
    end

    context "when in-use" do
      let(:status) { "in-use" }

      it "validation fails" do
        expect(cloud_volume.supports?(:delete)).to be_falsy
      end
    end

    context "when ems is missing" do
      let(:ems_storage) { nil }

      it "validation fails" do
        expect(cloud_volume.supports?(:delete)).to be_falsy
      end
    end
  end

  describe "#supports?(:attach)" do
    context "when available" do
      context "multi_attachment enabled" do
        let(:multi_attachment) { true }

        it "validation passes" do
          expect(cloud_volume.supports?(:attach)).to be_truthy
        end
      end

      context "multi_attachment disabled" do
        let(:multi_attachment) { false }

        it "validation passes" do
          expect(cloud_volume.supports?(:attach)).to be_truthy
        end
      end
    end

    context "when in-use" do
      let(:status) { "in-use" }

      context "multi_attachment enabled" do
        let(:multi_attachment) { true }

        it "validation passes" do
          expect(cloud_volume.supports?(:attach)).to be_truthy
        end
      end

      context "multi_attachment disabled" do
        let(:multi_attachment) { false }

        it "validation fails" do
          expect(cloud_volume.supports?(:attach)).to be_falsy
        end
      end
    end

    context "when ems is missing" do
      let(:ems_storage) { nil }

      it "validation fails" do
        expect(cloud_volume.supports?(:attach)).to be_falsy
      end
    end
  end

  describe "#supports?(:detach_volume)" do
    context "when available" do
      it "validation fails" do
        expect(cloud_volume.supports?(:detach)).to be_falsy
      end
    end

    context "when in-use" do
      let(:status) { "in-use" }

      it "validation passes" do
        expect(cloud_volume.supports?(:detach)).to be_truthy
      end
    end

    context "when ems is missing" do
      let(:ems_storage) { nil }

      it "validation fails" do
        expect(cloud_volume.supports?(:detach)).to be_falsy
      end
    end
  end
end
