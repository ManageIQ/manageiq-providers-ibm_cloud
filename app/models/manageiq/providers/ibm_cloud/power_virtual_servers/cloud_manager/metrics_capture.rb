class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::MetricsCapture < ManageIQ::Providers::CloudManager::MetricsCapture
  delegate :ext_management_system, :to => :target

  # IBM Cloud Monitoring uses dataSourceType "host" for PowerVS platform metrics.
  # Sampling is 60s; we interpolate down to MIQ's expected 20s realtime intervals.
  VIM_STYLE_COUNTERS = {
    "cpu_usage_rate_average"     => {
      :counter_key           => "cpu_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 1,
      :rollup                => "average",
      :unit_key              => "percent",
      :capture_interval_name => "realtime",
    }.freeze,
    "mem_usage_absolute_average" => {
      :counter_key           => "mem_usage_absolute_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 1,
      :rollup                => "average",
      :unit_key              => "percent",
      :capture_interval_name => "realtime",
    }.freeze,
    "net_usage_rate_average"     => {
      :counter_key           => "net_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 2,
      :rollup                => "average",
      :unit_key              => "kilobytespersecond",
      :capture_interval_name => "realtime",
    }.freeze,
    "disk_usage_rate_average"    => {
      :counter_key           => "disk_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 2,
      :rollup                => "average",
      :unit_key              => "kilobytespersecond",
      :capture_interval_name => "realtime",
    }.freeze,
  }.freeze

  # IBM Cloud Monitoring metric names for PowerVS (ibm_power_iaas namespace).
  # Order here must match the index positions used in #consolidate_data.
  POWERVS_METRICS = [
    "ibm_power_iaas_pvm_instance_cpu_util",               # index 0 -> cpu %
    "ibm_power_iaas_pvm_instance_mem_util",               # index 1 -> mem %
    "ibm_power_iaas_pvm_instance_network_incoming_bytes", # index 2 -> net in (bytes)
    "ibm_power_iaas_pvm_instance_network_outgoing_bytes", # index 3 -> net out (bytes)
    "ibm_power_iaas_pvm_instance_disk_read_bytes",        # index 4 -> disk read (bytes)
    "ibm_power_iaas_pvm_instance_disk_write_bytes",       # index 5 -> disk write (bytes)
  ].freeze

  def perf_collect_metrics(interval_name, start_time = nil, end_time = nil)
    # IBM Cloud does not publish a Ruby SDK for the Monitoring Data API (/api/data).
    # The existing ibm_cloud_sdk_core / ibm_cloud_iam SDKs cover IAM and resource
    # management only, so we use Faraday for the metrics query directly.
    require 'faraday'

    raise _("No EMS defined") if ext_management_system.nil?

    end_time   ||= Time.zone.now
    end_time     = end_time.utc
    start_time ||= end_time - 4.hours
    start_time   = start_time.utc

    sample_window = end_time.to_i - start_time.to_i

    counters_by_mor       = {target.ems_ref => VIM_STYLE_COUNTERS}
    counter_values_by_mor = {target.ems_ref => {}}

    metrics_endpoint = ext_management_system.metrics_endpoint
    raise _("No metrics endpoint has been added") if metrics_endpoint.nil?

    instance_id = metrics_endpoint.options["monitoring_instance_id"]
    region      = monitoring_region

    post_body    = JSON.generate(build_metrics_query(target.name, sample_window))
    post_headers = {
      "Content-Type"  => "application/json",
      "Authorization" => "Bearer #{iam_access_token}",
      "IBMInstanceID" => instance_id
    }

    response = Faraday.post("https://#{region}.monitoring.cloud.ibm.com/api/data", post_body, post_headers)
    raise Faraday::ClientError, response unless response.success?

    data    = JSON.parse(response.body)
    dataset = consolidate_data(data["data"])

    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:cpu_usage_rate_average],     "cpu_usage_rate_average",     counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:mem_usage_absolute_average], "mem_usage_absolute_average", counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:net_usage_rate_average],     "net_usage_rate_average",     counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:disk_usage_rate_average],    "disk_usage_rate_average",    counter_values_by_mor[target.ems_ref])

    return counters_by_mor, counter_values_by_mor
  rescue Faraday::Error => err
    log_header = "[#{interval_name}] for: [#{target.class.name}], [#{target.id}], [#{target.name}]"
    _log.error("#{log_header} Unhandled exception during perf data collection: [#{err}], class: [#{err.class}]")
    _log.log_backtrace(err)
    raise
  end

  private

  # Build the IBM Cloud Monitoring query payload.
  # @param instance_name [String] PVM instance name used as the label filter.
  # @param sample_window [Integer] Seconds to look back from "now".
  def build_metrics_query(instance_name, sample_window)
    {
      :last           => sample_window,
      :sampling       => 60,
      :filter         => "ibm_resource_name = '#{instance_name}'",
      :metrics        => POWERVS_METRICS.map do |metric_id|
        {
          :id           => metric_id,
          :aggregations => {
            :time => "avg",
          }
        }
      end,
      :dataSourceType => "host",
    }
  end

  # Resolve the IBM Cloud Monitoring regional endpoint hostname prefix from the
  # PowerVS region stored on the EMS (e.g. "dal10" -> "us-south").
  # The :monitoring_endpoint key in the Regions registry maps each PowerVS region
  # slug to the corresponding IBM Cloud Monitoring endpoint prefix.
  # Source: https://cloud.ibm.com/docs/monitoring?topic=monitoring-endpoints
  def monitoring_region
    raw = ext_management_system.provider_region.presence
    raise "Cannot determine monitoring region: provider_region is blank" if raw.nil?

    # "dal10" -> "dal", "eu-de-2" -> "eu-de", "us-south" -> "us-south"
    pvs_region = raw.sub(/-*\d+$/, '')

    region_data = ManageIQ::Providers::IbmCloud::PowerVirtualServers::Regions.regions[pvs_region]
    unless region_data&.dig(:monitoring_endpoint)
      raise _("IBM Cloud Monitoring is not available for PowerVS region '%{region}'. " \
              "Ensure an IBM Cloud Monitoring instance exists in the same region as this PowerVS workspace.") % {:region => pvs_region}
    end

    region_data[:monitoring_endpoint]
  end

  def iam_access_token
    @iam_access_token ||= begin
      require 'ibm_cloud_sdk_core'
      IBMCloudSdkCore::IAMTokenManager.new(
        :apikey => ext_management_system.authentication_key("default")
      ).access_token
    end
  end

  # Collapse raw API datapoints into per-counter arrays, converting byte-based
  # metrics to KB/s (matching the unit_key declared in VIM_STYLE_COUNTERS).
  #
  # Each datapoint returned by IBM Cloud Monitoring has the shape:
  #   { "t" => <unix_timestamp_integer>,
  #     "d" => [cpu_pct, mem_pct, net_in_bytes, net_out_bytes, disk_read_bytes, disk_write_bytes] }
  # Index positions correspond to the order declared in POWERVS_METRICS.
  def consolidate_data(datapoints)
    dataset = {
      :timestamps                 => [],
      :cpu_usage_rate_average     => [],
      :mem_usage_absolute_average => [],
      :net_usage_rate_average     => [],
      :disk_usage_rate_average    => [],
    }
    Array(datapoints).each do |dp|
      dataset[:timestamps]                 << dp["t"]
      dataset[:cpu_usage_rate_average]     << dp["d"][0].to_f  # cpu_pct (%)
      dataset[:mem_usage_absolute_average] << dp["d"][1].to_f  # mem_pct (%)
      # Network: sum in+out bytes, convert to KB/s
      dataset[:net_usage_rate_average]  << ((dp["d"][2].to_f + dp["d"][3].to_f) / 1.kilobyte)
      # Disk: sum read+write bytes, convert to KB/s
      dataset[:disk_usage_rate_average] << ((dp["d"][4].to_f + dp["d"][5].to_f) / 1.kilobyte)
    end
    dataset
  end

  # Write a datapoint at each 60s sample and interpolate forward to fill the
  # 20s realtime buckets ManageIQ expects (same pattern as VPC).
  def store_datapoints_with_interpolation!(end_time, timestamps, datapoints, counter_key, counter_values)
    timestamps.zip(datapoints).each do |timestamp, value|
      [timestamp, timestamp + 20, timestamp + 40].each do |ts|
        next if ts > end_time

        counter_values.store_path(Time.at(ts).utc, counter_key, value)
      end
    end
  end
end
