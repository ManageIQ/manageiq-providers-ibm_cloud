class ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager < ManageIQ::Providers::StorageManager
  require_nested :Refresher
  require_nested :RefreshWorker

  supports :ems_storage_new
  include ManageIQ::Providers::StorageManager::ObjectMixin

  def self.params_for_create
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
                        :component  => "text-field",
                        :name       => "provider_region",
                        :id         => "provider_region",
                        :label      => _("Region"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "text-field",
                        :name       => "uid_ems",
                        :id         => "uid_ems",
                        :label      => _("Resource Instance Id"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "text-field",
                        :name       => "endpoints.default.url",
                        :id         => "endpoints.default.url",
                        :label      => _("Endpoint"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "text-field",
                        :name       => "authentications.default.auth_key",
                        :id         => "authentications.default.auth_key",
                        :label      => _("Apikey"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                        :type       => "password",
                      },
                      {
                        :component  => "text-field",
                        :name       => "authentications.bearer.userid",
                        :id         => "authentications.bearer.userid",
                        :label      => _("Access Key"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                      },
                      {
                        :component  => "text-field",
                        :name       => "authentications.bearer.password",
                        :id         => "authentications.bearer.password",
                        :label      => _("Secret Key"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],
                        :type       => "password",
                      }
                    ]
                  }
                ]
              }
            ]
          ]
        }
      ]
    }.freeze
  end

  def self.hostname_required?
    false
  end

  def self.supported_for_create?
    true
  end

  def self.ems_type
    @ems_type ||= "ibm_cloud_object_storage".freeze
  end

  def self.description
    @description ||= "IBM Cloud Object Storage".freeze
  end

  def image_name
    "ibm"
  end

  def get_cos_creds
    iam     = authentications.detect { |e| e.authtype == 'default' } || {}
    bearer  = authentications.detect { |e| e.authtype == 'bearer' }  || {}
    endp    = endpoints.detect { |e| e.role == 'default' } || {}

    guid   = uid_ems
    region = provider_region
    endpoint = endp.url
    apikey   = iam.auth_key
    access_key = bearer.userid
    secret_encr = bearer.password
    secret_key  = ManageIQ::Password.try_decrypt(secret_encr)

    return guid, apikey, region, endpoint, access_key, secret_key
  end

  def connect(_args = {})
    guid, apikey, region, endpoint, access_key, secret_key = get_cos_creds
    self.class.raw_connect(region, endpoint, access_key, secret_key)
  end

  def verify_credentials(_args = {})
    guid, apikey, region, endpoint, access_key, secret_key = get_cos_creds
    self.class.verify_bearer(region, endpoint, access_key, secret_key)
    self.class.verify_iam(guid, apikey)
    true
  end

  def self.verify_credentials(args)
    guid     = args["uid_ems"]
    auth_key = args.dig("authentications", "default", "auth_key")
    apikey  = ManageIQ::Password.try_decrypt(auth_key)
    verify_iam(guid, apikey)

    region = args["provider_region"]
    endpoint = args.dig("endpoints", "default", "url")
    access_key = args.dig("authentications", "bearer", "userid")
    secret_encr = args.dig("authentications", "bearer", "password")
    secret_key  = ManageIQ::Password.try_decrypt(secret_encr)
    verify_bearer(region, endpoint, access_key, secret_key)

    true
  end

  private

  def self.verify_bearer(region, endpoint, access_key, secret_key)
    begin
      self.raw_connect(region, endpoint, access_key, secret_key).list_buckets({}, params: {max_keys: 1})
      return true
    rescue IbmCloudIam::ApiError => err
      error_message = JSON.parse(err.response_body)["message"]
      _log.error("Access/Secret authentication failed: #{err.code} #{error_message}")
      raise MiqException::MiqInvalidCredentialsError, error_message
    end
  end

  def self.verify_iam(crn, api_key)
    begin
      require "ibm_cloud_iam"
      iam_token_api = IbmCloudIam::TokenOperationsApi.new
      token = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)
    rescue IbmCloudIam::ApiError => err
      error_message = JSON.parse(err.response_body)["message"]
      _log.error("IAM authentication failed: #{err.code} #{error_message}")
      raise MiqException::MiqInvalidCredentialsError, error_message
    end

    require "ibm_cloud_resource_controller"
    api_client = IbmCloudResourceController::ApiClient.new
    api_client.config.api_key        = {"Authorization" => token.access_token}
    api_client.config.api_key_prefix = {"Authorization" => token.token_type}
    api_client.config.access_token   = {"Authorization" => token.access_token}
    api_client.config.logger         = $ibm_cloud_log

    resource_instances_api = IbmCloudResourceController::ResourceInstancesApi.new(api_client)

    begin
      resource_instances_api.get_resource_instance(crn)
    rescue IbmCloudResourceController::ApiError => err
      error_message = JSON.parse(err.response_body)["message"]
      _log.error("GUID resource lookup failed: #{err.code} #{error_message}")
      raise MiqException::MiqInvalidCredentialsError, error_message
    end

    return true
  end

  def self.raw_connect(region, endpoint, access_key, secret_key)
    require "aws-sdk-s3"

    options = {
      :credentials   => Aws::Credentials.new(access_key, secret_key),
      :region        => region,
      :logger        => $ibm_cloud_log,
      :log_level     => :debug,
      :log_formatter => Aws::Log::Formatter.new(Aws::Log::Formatter.default.pattern.chomp),
      :endpoint      => endpoint,
    }

    Aws.const_get(:S3)::Resource.new(options).client
  end
end