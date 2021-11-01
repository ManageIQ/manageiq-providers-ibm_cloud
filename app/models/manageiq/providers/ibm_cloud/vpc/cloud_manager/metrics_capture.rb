class ManageIQ::Providers::IbmCloud::VPC::CloudManager::MetricsCapture < ManageIQ::Providers::CloudManager::MetricsCapture
  delegate :ext_management_system, :to => :target

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
    "disk_usage_rate_average"    => {
      :counter_key           => "disk_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 2,
      :rollup                => "average",
      :unit_key              => "kilobytespersecond",
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
    "mem_usage_absolute_average" => {
      :counter_key           => "mem_usage_absolute_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 1,
      :rollup                => "average",
      :unit_key              => "percent",
      :capture_interval_name => "realtime",
    }.freeze,
  }.freeze

  def perf_collect_metrics(interval_name, start_time = nil, end_time = nil)
    require 'rest-client'

    raise _("No EMS defined") if ext_management_system.nil?

    end_time ||= Time.zone.now
    end_time = end_time.utc
    start_time ||= end_time - 4.hours
    start_time = start_time.utc
    # Due to API limitations, the maximum period of time that can be sampled over is 36000 seconds (10 hours)
    sample_window = (end_time.to_i - start_time.to_i) > 36_000 ? 36_000 : end_time.to_i - start_time.to_i

    counters_by_mor = {target.ems_ref => VIM_STYLE_COUNTERS}
    counter_values_by_mor = {target.ems_ref => {}}

    metrics_endpoint = ext_management_system.endpoints.find_by(:role => "metrics")
    raise _("Missing monitoring instance id") if metrics_endpoint.nil?

    instance_id = metrics_endpoint.options["monitoring_instance_id"]

    response = RestClient::Request.execute(
      :method  => :post,
      :url     => "https://#{ext_management_system.provider_region}.monitoring.cloud.ibm.com/api/data",
      :headers => {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{iam_access_token}",
        'IBMInstanceID' => instance_id
      },
      :payload => JSON.generate(get_metrics_query(target.name, sample_window))
    )
    data = JSON.parse(response.body)
    dataset = consolidate_data(data["data"])

    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:cpu_usage_rate_average], "cpu_usage_rate_average", counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:mem_usage_absolute_average], "mem_usage_absolute_average", counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:net_usage_rate_average], "net_usage_rate_average", counter_values_by_mor[target.ems_ref])
    store_datapoints_with_interpolation!(end_time.to_i, dataset[:timestamps], dataset[:disk_usage_rate_average], "disk_usage_rate_average", counter_values_by_mor[target.ems_ref])

    return counters_by_mor, counter_values_by_mor
  rescue RestClient::ExceptionWithResponse => err
    log_header = "[#{interval_name}] for: [#{target.class.name}], [#{target.id}], [#{target.name}]"
    _log.error("#{log_header} Unhandled exception during perf data collection: [#{err}], class: [#{err.class}]")
    _log.log_backtrace(err)
    raise
  end

  def get_metrics_query(instance_name, sample_window)
    # :last refers to the window of time in which data will be retrieved
    # :sampling refers to the data resolution, data will be sampled every 60 seconds
    {
      :last           => sample_window,
      :sampling       => 60,
      :filter         => "ibm_resource_name = '#{instance_name}'",
      :metrics        => [
        {
          :id           => "ibm_is_instance_cpu_usage_percentage",
          :aggregations => {
            :time => "avg"
          }
        },
        {
          :id           => "ibm_is_instance_memory_usage_percentage",
          :aggregations => {
            :time => "avg"
          }
        },
        {
          :id           => "ibm_is_instance_network_in_bytes",
          :aggregations => {
            :time => "avg"
          }
        },
        {
          :id           => "ibm_is_instance_network_out_bytes",
          :aggregations => {
            :time => "avg"
          }
        },
        {
          :id           => "ibm_is_instance_volume_read_bytes",
          :aggregations => {
            :time => "avg"
          }
        },
        {
          :id           => "ibm_is_instance_volume_write_bytes",
          :aggregations => {
            :time => "avg"
          }
        }
      ],
      :dataSourceType => "host"
    }
  end

  def iam_access_token
    @iam_access_token ||= IBMCloudSdkCore::IAMTokenManager.new(:apikey => ext_management_system.authentication_key("default")).access_token
  end

  def store_datapoints_with_interpolation!(end_time, timestamps, datapoints, counter_key, counter_values_by_mor)
    timestamps.zip(datapoints).each do |timestamp, datapoint|
      counter_values_by_mor.store_path(Time.at(timestamp).utc, counter_key, datapoint)

      # Interpolate data to expected 20 second intervals
      [timestamp + 20, timestamp + 40].each do |interpolated_ts|
        # Make sure we don't interpolate past the requested range
        next if interpolated_ts > end_time

        counter_values_by_mor.store_path(Time.at(interpolated_ts).utc, counter_key, datapoint)
      end
    end
  end

  def consolidate_data(datapoints)
    dataset = {:timestamps => [], :cpu_usage_rate_average => [], :mem_usage_absolute_average => [], :net_usage_rate_average => [], :disk_usage_rate_average => []}
    datapoints.each do |datapoint|
      dataset[:timestamps] << datapoint["t"]
      dataset[:cpu_usage_rate_average] << datapoint["d"][0]
      dataset[:mem_usage_absolute_average] << datapoint["d"][1]
      dataset[:net_usage_rate_average] << (datapoint["d"][2] + datapoint["d"][3]) / 1.kilobyte
      dataset[:disk_usage_rate_average] << (datapoint["d"][4] + datapoint["d"][5]) / 1.kilobyte
    end

    dataset
  end
end
