describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::MetricsCapture do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "ca-tor").tap do |ems|
      ems.endpoints << FactoryBot.create(:endpoint, :role => "metrics", :options => {"monitoring_instance_id" => "238fa410-548f-4d71-af83-8d8bcd91a122"})
    end
  end
  let(:vm) { FactoryBot.create(:vm_ibm_cloud_vpc, :ext_management_system => ems, :ems_ref => "02r7_822df12d-b78c-4348-85c5-c74b9d31c32f") }

  describe "#perf_collect_metrics" do
    it "collects metrics" do
      VCR.use_cassette(described_class.name.underscore) do
        vm.perf_capture_realtime
      end

      vm.reload

      expect(vm.metrics.count).to eq(6)
    end
  end
end
