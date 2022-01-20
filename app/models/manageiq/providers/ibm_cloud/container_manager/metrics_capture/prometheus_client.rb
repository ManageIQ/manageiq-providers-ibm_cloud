class ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture::PrometheusClient < ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCapture::PrometheusClient

  def prometheus_client
    @prometheus_uri ||= prometheus_uri
    @prometheus_headers ||= prometheus_headers
    @prometheus_options ||= prometheus_options

    prometheus_client_new(@prometheus_uri, @prometheus_headers, @prometheus_options)
  end

  def prometheus_client_new(uri, headers, options)
    Prometheus::ApiClient.client(
      :url     => uri.to_s,
      :options => options,
      :headers => headers
    )
  end

  def prometheus_uri
    URI::HTTPS.build(
      :host => prometheus_endpoint.hostname,
      :port => prometheus_endpoint.port,
      :path => "/prometheus"
    )
  end

  def prometheus_headers
    {
      :Authorization => "Bearer #{IBMCloudSdkCore::IAMTokenManager.new(:apikey => @ext_management_system.authentication_key("prometheus")).access_token}",
      :IBMInstanceID => prometheus_endpoint.options["monitoring_instance_id"]
    }
  end
end
