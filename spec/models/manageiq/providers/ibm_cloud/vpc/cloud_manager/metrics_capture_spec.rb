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

  describe "#perf_collect_metrics (Faraday.post)" do
    subject { described_class.new(vm) }

    let(:fake_response) do
      instance_double(
        Faraday::Response,
        :success? => true,
        :body     => JSON.generate(
          "data" => [
            {"t" => 1_700_000_000, "d" => [10.0, 20.0, 1024.0, 512.0, 2048.0, 1024.0]},
            {"t" => 1_700_000_060, "d" => [15.0, 25.0, 2048.0, 1024.0, 4096.0, 2048.0]},
          ]
        )
      )
    end

    before { allow(subject).to receive(:iam_access_token).and_return("fake-token") }

    it "calls Faraday.post with the correct URL, body, and headers" do
      expect(Faraday).to receive(:post).with(
        "https://ca-tor.monitoring.cloud.ibm.com/api/data",
        satisfy { |body|
          parsed = JSON.parse(body)
          parsed["dataSourceType"] == "host" &&
            parsed["filter"].include?(vm.name) &&
            parsed["metrics"].map { |m| m["id"] }.sort == %w[
              ibm_is_instance_cpu_usage_percentage
              ibm_is_instance_memory_usage_percentage
              ibm_is_instance_network_in_bytes
              ibm_is_instance_network_out_bytes
              ibm_is_instance_volume_read_bytes
              ibm_is_instance_volume_write_bytes
            ].sort
        },
        {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer fake-token",
          "IBMInstanceID" => "238fa410-548f-4d71-af83-8d8bcd91a122"
        }
      ).and_return(fake_response)

      counters, counter_values = subject.perf_collect_metrics("realtime")

      expect(counters[vm.ems_ref]).to include("cpu_usage_rate_average", "mem_usage_absolute_average", "net_usage_rate_average", "disk_usage_rate_average")
      expect(counter_values[vm.ems_ref]).not_to be_empty
    end

    it "raises Faraday::Error when the response is not successful" do
      error_response = instance_double(Faraday::Response, :success? => false)
      allow(Faraday).to receive(:post).and_return(error_response)

      expect { subject.perf_collect_metrics("realtime") }.to raise_error(Faraday::Error)
    end
  end
end
