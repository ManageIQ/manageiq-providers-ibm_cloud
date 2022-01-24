class ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture::PrometheusCaptureContext < ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCapture::PrometheusCaptureContext
  def initialize(target, start_time, end_time, interval)
    @target = target
    @starts = start_time.to_i.in_milliseconds
    @ends = end_time.to_i.in_milliseconds if end_time
    @interval = interval.to_i
    @tenant = target.try(:container_project).try(:name) || '_system'
    @ext_management_system = @target.ext_management_system
    @ts_values = Hash.new { |h, k| h[k] = {} }
    @metrics = []

    @node_hardware = if @target.respond_to?(:hardware)
                       @target.hardware
                     else
                       @target.try(:container_node).try(:hardware)
                     end

    @node_cores = @node_hardware.try(:cpu_total_cores)
    @node_memory = @node_hardware.try(:memory_mb)

    validate_target
  end

  def collect_node_metrics
    # set node labels
    labels = labels_to_s(:kube_node_name => @target.name)

    @metrics = %w(cpu_usage_rate_average mem_usage_absolute_average net_usage_rate_average)
    collect_metrics_for_labels(labels)
  end

  def collect_container_metrics
    # set container labels
    labels = labels_to_s(
      :container_name      => @target.name,
      :kube_pod_name       => @target.container_group.name,
      :kube_namespace_name => @target.container_project.name,
    )

    @metrics = %w(cpu_usage_rate_average mem_usage_absolute_average)
    collect_metrics_for_labels(labels)
  end

  def collect_group_metrics
    # set pod labels

    labels = labels_to_s(
      :kube_pod_name       => @target.name,
      :kube_namespace_name => @target.container_project.name,
    )

    @metrics = %w(cpu_usage_rate_average mem_usage_absolute_average net_usage_rate_average)
    collect_metrics_for_labels(labels)
  end

  def collect_metrics_for_labels(labels)
    # promQL field is in pct of cpu cores
    # miq field is in pct of node cpu
    cpu_resid = "sum(sysdig_container_cpu_cores_used_percent{#{labels}})"
    fetch_counters_data(cpu_resid, 'cpu_usage_rate_average')

    # promQL field is in bytes, @node_memory is in mb
    # miq field is in pct of node memory
    mem_resid = "sum(sysdig_container_memory_used_bytes{#{labels}})"
    fetch_counters_data(mem_resid, 'mem_usage_absolute_average', @node_memory * 1e6 / 100.0)

    # promQL field is in bytes
    # miq field is on kb ( / 1000 )
    if @metrics.include?('net_usage_rate_average')
      net_resid = "sum(rate(sysdig_container_net_in_bytes{#{labels}}[#{AVG_OVER}])) + " \
                  "sum(rate(sysdig_container_net_out_bytes{#{labels}}[#{AVG_OVER}]))"
      fetch_counters_data(net_resid, 'net_usage_rate_average', 1000.0)
    end

    @ts_values
  end

  def fetch_counters_data(resource, metric_title, conversion_factor = 1)
    start_sec = (@starts / 1_000) - @interval
    end_sec = @ends ? (@ends / 1_000).to_i : Time.now.utc.to_i

    sort_and_normalize(
      prometheus_client.query_range(
        :query => resource,
        :start => start_sec.to_i,
        :end   => end_sec,
        :step  => "#{@interval}s"
      ),
      metric_title,
      conversion_factor
    )
  rescue NoMetricsFoundError
    raise
  rescue StandardError => e
    raise CollectionFailure, "#{e.class.name}: #{e.message}"
  end

  def labels_to_s(labels)
    labels.compact.sort.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
  end

  def prometheus_client
    @prometheus_client ||= ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture::PrometheusClient.new(@ext_management_system).prometheus_client
  end
end
