module ManageIQ::Providers::IbmCloud::PowerVirtualServers::ManagerMixin
  extend ActiveSupport::Concern

  def required_credential_fields(_type)
    [:auth_key]
  end

  def supported_auth_attributes
    %w[auth_key]
  end

  def connect(options = {})
    auth_key = authentication_key(options[:auth_type])
    token, power_iaas_service = self.class.raw_connect(auth_key, uid_ems)

    location = parse_crn(power_iaas_service["crn"])[:location]

    require "ibm_cloud_power"
    power_api_client = IbmCloudPower::ApiClient.new

    power_api_client.config.api_key = auth_key
    power_api_client.config.scheme  = "https"
    power_api_client.config.host    = api_endpoint_url(location)
    power_api_client.config.logger  = $ibm_cloud_log
    power_api_client.config.debugging = Settings.log.level_ibm_cloud == "debug"
    power_api_client.default_headers["Crn"]           = power_iaas_service["crn"]
    power_api_client.default_headers["Authorization"] = "#{token.token_type} #{token.access_token}"

    if options[:service]
      api_klass = "IbmCloudPower::#{options[:service]}".safe_constantize
      raise ArgumentError, _("Unknown target API set: '%{service_type}'") % {:service_type => options[:service]} if api_klass.nil?

      api_klass.new(power_api_client)
    else
      power_api_client
    end
  end

  def api_endpoint_url(location)
    api_endpoint_overrides = ::Settings.ems.ems_ibm_cloud_power_virtual_servers.api_endpoint_overrides

    if api_endpoint_overrides.key?(location.to_sym)
      url = api_endpoint_overrides[location.to_sym]
    else
      region = location.sub(/-\d$/, '')
      region = region.sub(/\d\d$/, '')
      url = "#{region}.power-iaas.cloud.ibm.com"
    end

    url
  end

  def verify_credentials(_auth_type = nil, options = {})
    connect(options)
    true
  end

  def pcloud_tenant_id(connection = nil)
    connection ||= connect
    parse_crn(connection.default_headers["Crn"])[:scope].split("/").last
  end

  private

  def parse_crn(crn)
    crn, version, cname, ctype, service_name, location, scope, service_instance, resource_type, resource = crn.split(":")

    {
      :crn              => crn,
      :version          => version,
      :cname            => cname,
      :cype             => ctype,
      :service_name     => service_name,
      :location         => location,
      :scope            => scope,
      :service_instance => service_instance,
      :resource_type    => resource_type,
      :resource         => resource
    }
  end

  module ClassMethods
    def params_for_create
      @params_for_create ||= {
        :fields => [
          {
            :component => 'sub-form',
            :id        => 'endpoints-subform',
            :name      => 'endpoints-subform',
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
                      :id                     => 'endpoints.default.valid',
                      :name                   => 'endpoints.default.valid',
                      :skipSubmit             => true,
                      :isRequired             => true,
                      :validationDependencies => %w[type zone_id uid_ems],
                      :fields                 => [
                        {
                          :component  => "password-field",
                          :name       => "authentications.default.auth_key",
                          :id         => "authentications.default.auth_key",
                          :label      => _("IBM Cloud API Key"),
                          :type       => "password",
                          :isRequired => true,
                          :validate   => [{:type => "required"}]
                        },
                        {
                          :component  => "text-field",
                          :name       => "uid_ems",
                          :id         => "uid_ems",
                          :label      => _("PowerVS Service GUID"),
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        }
                      ]
                    }
                  ]
                },
              ]
            ]
          }
        ]
      }.freeze
    end

    def verify_credentials(args)
      pcloud_guid = args["uid_ems"]
      auth_key = args.dig("authentications", "default", "auth_key")
      auth_key = ManageIQ::Password.try_decrypt(auth_key)
      auth_key ||= find(args["id"]).authentication_token('default')

      !!raw_connect(auth_key, pcloud_guid)
    end

    def raw_connect(api_key, pcloud_guid)
      if api_key.blank? || pcloud_guid.blank?
        raise MiqException::MiqInvalidCredentialsError, _("Missing credentials")
      end

      require "ibm_cloud_iam"
      iam_token_api = IbmCloudIam::TokenOperationsApi.new

      begin
        token = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)
      rescue IbmCloudIam::ApiError => err
        error_message = JSON.parse(err.response_body)["message"]
        _log.error("IAM authentication failed: #{err.code} #{error_message}")
        raise MiqException::MiqInvalidCredentialsError, error_message
      end

      require "ibm_cloud_resource_controller"
      authenticator = IbmCloudResourceController::Authenticators::BearerTokenAuthenticator.new(:bearer_token => token.access_token)
      resource_controller_api = IbmCloudResourceController::ResourceControllerV2.new(:authenticator => authenticator)

      begin
        power_iaas_service = resource_controller_api.get_resource_instance(:id => pcloud_guid).result
      rescue IbmCloudResourceController::ApiException => err
        _log.error("GUID resource lookup failed: #{err.code} #{err.error}")
        raise MiqException::MiqInvalidCredentialsError, err.error
      end

      [token, power_iaas_service]
    end
  end
end
