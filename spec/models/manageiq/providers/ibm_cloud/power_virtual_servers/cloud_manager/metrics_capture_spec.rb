describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::MetricsCapture do
  let(:ems) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud_with_metrics) }
  let(:vm)  { FactoryBot.create(:vm_ibm_cloud_power_virtual_servers, :ext_management_system => ems, :name => "test-pvm-instance", :ems_ref => "aaaabbbb-1111-2222-3333-ccccddddeeee") }

  describe "#perf_collect_metrics" do
    subject { described_class.new(vm) }

    it "collects metrics and stores datapoints" do
      fake_response = instance_double(
        Faraday::Response,
        :success? => true,
        :body     => JSON.generate(
          "data" => [
            {"t" => 1_700_000_000, "d" => [50.0, 60.0, 1024.0, 512.0, 2048.0, 1024.0]},
            {"t" => 1_700_000_060, "d" => [55.0, 65.0, 2048.0, 1024.0, 4096.0, 2048.0]},
          ]
        )
      )

      allow(subject).to receive(:iam_access_token).and_return("fake-token")
      expect(Faraday).to receive(:post).with(
        "https://us-south.monitoring.cloud.ibm.com/api/data",
        satisfy { |body|
          parsed = JSON.parse(body)
          parsed["dataSourceType"] == "host" &&
            parsed["filter"].include?("test-pvm-instance") &&
            parsed["metrics"].map { |m| m["id"] }.sort == ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::MetricsCapture::POWERVS_METRICS.sort
        },
        {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer fake-token",
          "IBMInstanceID" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        }
      ).and_return(fake_response)

      counters, counter_values = subject.perf_collect_metrics("realtime")

      expect(counters[vm.ems_ref]).to include("cpu_usage_rate_average")
      expect(counter_values[vm.ems_ref]).not_to be_empty
    end
  end

  describe "#build_metrics_query" do
    subject { described_class.new(vm) }

    it "produces a payload with all six PowerVS metric IDs" do
      query = subject.send(:build_metrics_query, "my-pvm", 3600)

      expect(query[:dataSourceType]).to eq("host")
      expect(query[:last]).to eq(3600)
      expect(query[:sampling]).to eq(60)
      expect(query[:filter]).to include("my-pvm")
      metric_ids = query[:metrics].map { |m| m[:id] }
      expect(metric_ids).to include(
        "ibm_power_iaas_pvm_instance_cpu_util",
        "ibm_power_iaas_pvm_instance_mem_util",
        "ibm_power_iaas_pvm_instance_network_incoming_bytes",
        "ibm_power_iaas_pvm_instance_network_outgoing_bytes",
        "ibm_power_iaas_pvm_instance_disk_read_bytes",
        "ibm_power_iaas_pvm_instance_disk_write_bytes"
      )
    end

    it "uses the passed sample_window as the :last value" do
      query = subject.send(:build_metrics_query, "my-pvm", 7_200)

      expect(query[:last]).to eq(7_200)
    end
  end

  describe "#consolidate_data" do
    subject { described_class.new(vm) }

    let(:raw_datapoints) do
      [
        {"t" => 1_700_000_000, "d" => [50.0, 60.0, 1024.0, 512.0, 2048.0, 1024.0]},
        {"t" => 1_700_000_060, "d" => [55.0, 65.0, 2048.0, 1024.0, 4096.0, 2048.0]},
      ]
    end

    it "extracts cpu and mem as-is" do
      result = subject.send(:consolidate_data, raw_datapoints)

      expect(result[:cpu_usage_rate_average]).to eq([50.0, 55.0])
      expect(result[:mem_usage_absolute_average]).to eq([60.0, 65.0])
    end

    it "sums network in+out and converts to KB/s" do
      result = subject.send(:consolidate_data, raw_datapoints)

      # (1024 + 512) / 1024 = 1.5, (2048 + 1024) / 1024 = 3.0
      expect(result[:net_usage_rate_average]).to eq([1.5, 3.0])
    end

    it "sums disk read+write and converts to KB/s" do
      result = subject.send(:consolidate_data, raw_datapoints)

      # (2048 + 1024) / 1024 = 3.0, (4096 + 2048) / 1024 = 6.0
      expect(result[:disk_usage_rate_average]).to eq([3.0, 6.0])
    end
  end

  describe "#perf_collect_metrics" do
    subject { described_class.new(vm) }

    it "raises when no EMS is present" do
      allow(subject).to receive(:ext_management_system).and_return(nil)

      expect { subject.perf_collect_metrics("realtime") }.to raise_error(RuntimeError, /No EMS defined/)
    end

    it "raises when no metrics endpoint is configured" do
      ems_no_metrics = FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
      vm_no_metrics  = FactoryBot.create(:vm_ibm_cloud_power_virtual_servers, :ext_management_system => ems_no_metrics)
      capture        = described_class.new(vm_no_metrics)

      allow(capture).to receive(:iam_access_token).and_return("fake-token")

      expect { capture.perf_collect_metrics("realtime") }.to raise_error(RuntimeError, /No metrics endpoint/)
    end
  end
end
