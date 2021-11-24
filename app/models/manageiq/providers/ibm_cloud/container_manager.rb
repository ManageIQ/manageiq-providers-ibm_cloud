ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::IbmCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerNode
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Refresher
  require_nested :RefreshWorker

  supports :create

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
    default_endpoint = args.dig("endpoints", "default")
    hostname, port, security_protocol, certificate_authority = default_endpoint&.values_at(
      "hostname", "port", "security_protocol", "certificate_authority"
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

    !!raw_connect(hostname, port, options)
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

  def self.params_for_create
    {
      :fields => [
        {
          :component => 'sub-form',
          :name      => 'endpoints-subform',
          :id        => 'endpoints-subform',
          :title     => _("Endpoints"),
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
