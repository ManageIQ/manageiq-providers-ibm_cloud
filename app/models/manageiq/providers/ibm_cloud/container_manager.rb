ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::IbmCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerNode
  require_nested :ContainerTemplate
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :MetricsCapture
  require_nested :MetricsCollectorWorker
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :ServiceInstance
  require_nested :ServiceOffering
  require_nested :ServiceParametersSet

  supports :create

  METRICS_ROLES = %w[prometheus].freeze

  supports :metrics do
    unsupported_reason_add(:metrics, _("No metrics endpoint has been added")) unless metrics_endpoint_exists?
  end

  def metrics_endpoint_exists?
    endpoints.where(:role => METRICS_ROLES).exists?
  end

  def self.ems_type
    @ems_type ||= "iks".freeze
  end

  def self.description
    @description ||= "IBM Cloud Kubernetes Service".freeze
  end

  def self.display_name(number = 1)
    n_('Container Provider (IBM Cloud)', 'Container Providers (IBM Cloud)', number)
  end

  def connect_options(options = {})
    authentication = authentication_best_fit(options.fetch(:auth_type, "bearer"))
    super.merge(:api_key => authentication.auth_key)
  rescue IbmCloudIam::ApiError => err
    error_message = JSON.parse(err.response_body)["message"]
    _log.error("IAM authentication failed: #{err.code} #{error_message}")
  end

  def self.kubernetes_auth_options(options)
    {
      :bearer_token => get_token(options[:api_key]).id_token
    }
  end

  def self.verify_credentials(args)
    endpoint_name = args.dig("endpoints").keys.first
    endpoint = args.dig("endpoints", endpoint_name)
    hostname, port, security_protocol, certificate_authority, endpoint_options = endpoint&.values_at(
      "hostname", "port", "security_protocol", "certificate_authority", "options"
    )

    api_key = ManageIQ::Password.try_decrypt(args.dig("authentications", "bearer", "auth_key"))

    unless certificate_authority.nil?
      cert_store = OpenSSL::X509::Store.new
                                       .add_cert(
                                         OpenSSL::X509::Certificate.new(certificate_authority)
                                       )
    end

    options = {
      :api_key     => api_key,
      :ssl_options => {
        :verify_ssl => security_protocol == 'ssl-without-validation' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER,
        :cert_store => cert_store
      }
    }
    options[:instance_id] = endpoint_options["monitoring_instance_id"] unless endpoint_options.nil?

    case endpoint_name
    when 'default'
      !!raw_connect(hostname, port, options)
    when 'prometheus'
      !!prometheus_connect(hostname, port, options)
    else
      raise MiqException::MiqInvalidCredentialsError, _("Unsupported endpoint")
    end
  end

  def self.get_token(api_key)
    require 'ibm_cloud_iam'

    iam_token_api = IbmCloudIam::TokenOperationsApi.new
    grant_type = 'urn:ibm:params:oauth:grant-type:apikey'
    header_params = {
      'Content-Type'  => 'application/x-www-form-urlencoded',
      'Authorization' => 'Basic a3ViZTprdWJl',
      'cache-control' => 'no-cache'
    }

    iam_token_api.get_token_api_key(grant_type, api_key, {:header_params => header_params})
  rescue IbmCloudIam::ApiError => err
    error_message = JSON.parse(err.response_body)["message"]
    _log.error("IAM authentication failed: #{err.code} #{error_message}")
  end

  def self.prometheus_connect(hostname, port, options)
    require 'prometheus/api_client'

    uri = raw_api_endpoint(hostname, port, "/prometheus").to_s
    headers = {
      :Authorization => "Bearer #{IBMCloudSdkCore::IAMTokenManager.new(:apikey => options[:api_key]).access_token}",
      :IBMInstanceID => options[:instance_id]
    }
    ssl_options = options[:ssl_options] || {:verify_ssl => OpenSSL::SSL::VERIFY_NONE}

    prometheus_options = {
      :http_proxy_uri => options[:http_proxy] || VMDB::Util.http_proxy_uri.to_s,
      :verify_ssl     => ssl_options[:verify_ssl],
      :ssl_cert_store => ssl_options[:ca_file],
    }

    Prometheus::ApiClient.client(:url => uri, :headers => headers, :options => prometheus_options)&.query(:query => "ALL")&.kind_of?(Hash)
  end

  def verify_prometheus_credentials
    client = ManageIQ::Providers::IbmCloud::ContainerManager::MetricsCapture::PrometheusClient.new(self)
    client.prometheus_try_connect
  end

  def self.params_for_create
    {
      :fields => [
        {
          :component => 'sub-form',
          :name      => 'endpoints-subform',
          :id        => 'endpoints-subform',
          :title     => _("Endpoints"),
          :fields    => [
            :component => 'tabs',
            :name      => 'tabs',
            :fields    => [
              {
                :component => 'tab-item',
                :id        => 'default-tab',
                :name      => 'default-tab',
                :title     => _('Default'),
                :fields    => [
                  {
                    :component              => 'validate-provider-credentials',
                    :id                     => 'authentications.bearer.valid',
                    :name                   => 'authentications.bearer.valid',
                    :skipSubmit             => true,
                    :isRequired             => true,
                    :validationDependencies => %w[type zone_id provider_region realm uid_ems],
                    :fields                 => [
                      {
                        :component    => "select",
                        :id           => "endpoints.default.security_protocol",
                        :name         => "endpoints.default.security_protocol",
                        :label        => _("Security Protocol"),
                        :isRequired   => true,
                        :validate     => [{:type => "required"}],
                        :initialValue => 'ssl-with-validation',
                        :options      => [
                          {
                            :label => _("SSL"),
                            :value => "ssl-with-validation"
                          },
                          {
                            :label => _("SSL trusting custom CA"),
                            :value => "ssl-with-validation-custom-ca"
                          },
                          {
                            :label => _("SSL without validation"),
                            :value => "ssl-without-validation",
                          },
                        ]
                      },
                      {
                        :component  => "text-field",
                        :id         => "endpoints.default.hostname",
                        :name       => "endpoints.default.hostname",
                        :label      => _("Hostname (or IPv4 or IPv6 address)"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "text-field",
                        :id         => "endpoints.default.port",
                        :name       => "endpoints.default.port",
                        :label      => _("API Port"),
                        :type       => "number",
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "textarea",
                        :id         => "endpoints.default.certificate_authority",
                        :name       => "endpoints.default.certificate_authority",
                        :label      => _("Trusted CA Certificates"),
                        :rows       => 10,
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                        :condition  => {
                          :when => 'endpoints.default.security_protocol',
                          :is   => 'ssl-with-validation-custom-ca',
                        },
                      },
                      {
                        :component  => "password-field",
                        :id         => "authentications.bearer.auth_key",
                        :name       => "authentications.bearer.auth_key",
                        :label      => _("IBM Cloud API Key"),
                        :type       => "password",
                        :isRequired => true,
                        :validate   => [{:type => "required"}]
                      }
                    ],
                  },
                ],
              },
              {
                :component => 'tab-item',
                :id        => 'metrics-tab',
                :name      => 'metrics-tab',
                :title     => _('Metrics'),
                :fields    => [
                  {
                    :component    => 'protocol-selector',
                    :id           => 'metrics_selection',
                    :name         => 'metrics_selection',
                    :skipSubmit   => true,
                    :initialValue => 'none',
                    :label        => _('Type'),
                    :options      => [
                      {
                        :label => _('Disabled'),
                        :value => 'none',
                      },
                      {
                        :label => _('Prometheus'),
                        :value => 'prometheus',
                        :pivot => 'endpoints.prometheus.hostname',
                      },
                    ],
                  },
                  {
                    :component              => 'validate-provider-credentials',
                    :id                     => "authentications.prometheus.valid",
                    :name                   => "authentications.prometheus.valid",
                    :skipSubmit             => true,
                    :isRequired             => true,
                    :validationDependencies => ['type', "metrics_selection", "authentications.bearer.auth_key"],
                    :condition              => {
                      :when => "metrics_selection",
                      :is   => 'prometheus',
                    },
                    :fields                 => [
                      {
                        :component    => "select",
                        :id           => "endpoints.prometheus.security_protocol",
                        :name         => "endpoints.prometheus.security_protocol",
                        :label        => _("Security Protocol"),
                        :isRequired   => true,
                        :initialValue => 'ssl-with-validation',
                        :validate     => [{:type => "required"}],
                        :options      => [
                          {
                            :label => _("SSL"),
                            :value => "ssl-with-validation"
                          },
                          {
                            :label => _("SSL trusting custom CA"),
                            :value => "ssl-with-validation-custom-ca"
                          },
                          {
                            :label => _("SSL without validation"),
                            :value => "ssl-without-validation"
                          },
                        ]
                      },
                      {
                        :component  => "text-field",
                        :id         => "endpoints.prometheus.hostname",
                        :name       => "endpoints.prometheus.hostname",
                        :label      => _("Hostname (or IPv4 or IPv6 address)"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                        :inputAddon => {
                          :after => {
                            :fields => [
                              {
                                :component => 'input-addon-button-group',
                                :id        => 'detect-prometheus-group',
                                :name      => 'detect-prometheus-group',
                                :fields    => [
                                  {
                                    :component    => 'detect-button',
                                    :id           => 'detect-prometheus-button',
                                    :name         => 'detect-prometheus-button',
                                    :label        => _('Detect'),
                                    :dependencies => [
                                      'endpoints.default.hostname',
                                      'endpoints.default.port',
                                      'endpoints.default.security_protocol',
                                      'endpoints.default.certificate_authority',
                                      'authentications.bearer.auth_key',
                                    ],
                                    :target       => 'endpoints.prometheus',
                                  },
                                ],
                              }
                            ],
                          },
                        },
                      },
                      {
                        :component    => "text-field",
                        :id           => "endpoints.prometheus.port",
                        :name         => "endpoints.prometheus.port",
                        :label        => _("API Port"),
                        :type         => "number",
                        :initialValue => 443,
                        :isRequired   => true,
                        :validate     => [{:type => "required"}],
                      },
                      {
                        :component  => "textarea",
                        :id         => "endpoints.prometheus.certificate_authority",
                        :name       => "endpoints.prometheus.certificate_authority",
                        :label      => _("Trusted CA Certificates"),
                        :rows       => 10,
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                        :condition  => {
                          :when => 'endpoints.prometheus.security_protocol',
                          :is   => 'ssl-with-validation-custom-ca',
                        },
                      },
                      {
                        :component  => 'password-field',
                        :id         => 'endpoints.prometheus.options.monitoring_instance_id',
                        :name       => 'endpoints.prometheus.options.monitoring_instance_id',
                        :label      => _('IBM Cloud Monitoring Instance GUID'),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                    ]
                  },
                ]
              },
            ]
          ]
        },
        {
          :component   => 'text-field',
          :id          => 'options.proxy_settings.http_proxy',
          :name        => 'options.proxy_settings.http_proxy',
          :label       => _('HTTP Proxy'),
          :helperText  => _('HTTP Proxy to connect ManageIQ to the provider. example: http://user:password@my_http_proxy'),
          :placeholder => VMDB::Util.http_proxy_uri.to_s
        }
      ]
    }
  end
end
