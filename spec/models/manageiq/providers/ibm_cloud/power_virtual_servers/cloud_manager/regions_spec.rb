RSpec.describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::Regions do
  let(:ems_settings_name) { :ems_ibm_cloud_power_virtual_servers }
  let(:additional_regions) { {:mars => {:name => :mars, :description => "The Red Planet", :hostname => "mars.power-iaas.cloud.ibm.com"}} }
  let(:disabled_regions) { ["dal"] }

  describe ".regions" do
    it "returns regions" do
      expect(described_class.regions.count).not_to be_zero
    end

    context "with additional_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:additional_regions => additional_regions}}
        )
      end

      it "includes the additional region" do
        expect(described_class.regions).to include("mars" => {:name => :mars, :description => "The Red Planet", :hostname => "mars.power-iaas.cloud.ibm.com"})
      end
    end

    context "with disabled_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:disabled_regions => disabled_regions}}
        )
      end

      it "excluded the additional region" do
        expect(described_class.regions).not_to include("dal")
      end
    end
  end

  describe ".all" do
    it "returns regions" do
      expect(described_class.all.count).not_to be_zero
    end

    context "with additional_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:additional_regions => additional_regions}}
        )
      end

      it "includes the additional region" do
        expect(described_class.all).to include({:name => :mars, :description => "The Red Planet", :hostname => "mars.power-iaas.cloud.ibm.com"})
      end
    end

    context "with disabled_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:disabled_regions => disabled_regions}}
        )
      end

      it "excluded the additional region" do
        expect(described_class.regions).not_to include("dal")
      end
    end
  end

  describe ".names" do
    it "returns regions" do
      expect(described_class.names.count).not_to be_zero
    end

    context "with additional_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:additional_regions => additional_regions}}
        )
      end

      it "includes the additional region" do
        expect(described_class.names).to include("mars")
      end
    end

    context "with disabled_regions" do
      before do
        stub_settings_merge(
          :ems => {ems_settings_name => {:disabled_regions => disabled_regions}}
        )
      end

      it "excluded the additional region" do
        expect(described_class.regions).not_to include("dal")
      end
    end
  end
end
