class ManageIQ::Providers::IbmCloud::ObjectStorage::StorageManager < ManageIQ::Providers::StorageManager
  require_nested :CloudObjectStoreContainer
  require_nested :CloudObjectStoreObject
  require_nested :Refresher
  require_nested :RefreshWorker

  supports :create
  supports :update

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
                      { :component  => "text-field",
                        :name       => "provider_region",
                        :id         => "provider_region",
                        :label      => _("Region"),
                        :isRequired => true,
                        :validate   => [{:type => "required"}],},
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

  def self.ems_type
    @ems_type ||= "ibm_cloud_object_storage".freeze
  end

  def self.description
    @description ||= "IBM Cloud Object Storage".freeze
  end

  def image_name
    "ibm_cloud"
  end

  def cos_creds
    guid       = uid_ems
    region     = provider_region
    endpoint   = default_endpoint.url
    apikey     = authentication_token("default")
    access_key = authentication_userid("bearer")
    secret_key = authentication_password("bearer")

    return guid, apikey, region, endpoint, access_key, secret_key
  end

  def connect(_args = {})
    _, _, region, endpoint, access_key, secret_key = cos_creds
    self.class.raw_connect(region, endpoint, access_key, secret_key)
  end

  def verify_credentials(_auth_type = nil, _options = {})
    guid, apikey, region, endpoint, access_key, secret_key = cos_creds
    self.class.verify_bearer(region, endpoint, access_key, secret_key)
    self.class.verify_iam(guid, apikey)

    true
  end

  def self.verify_credentials(args)
    guid     = args["uid_ems"]
    auth_key = args.dig("authentications", "default", "auth_key")
    apikey   = ManageIQ::Password.try_decrypt(auth_key)
    apikey ||= find(args["id"]).authentication_token("default")
    verify_iam(guid, apikey)

    region   = args["provider_region"]
    endpoint = args.dig("endpoints", "default", "url")

    access_key   = args.dig("authentications", "bearer", "userid")
    secret_encr  = args.dig("authentications", "bearer", "password")
    secret_key   = ManageIQ::Password.try_decrypt(secret_encr)
    secret_key ||= find(args["id"]).authentication_password("bearer")
    verify_bearer(region, endpoint, access_key, secret_key)

    true
  end

  def self.verify_bearer(region, endpoint, access_key, secret_key)
    begin
      raw_connect(region, endpoint, access_key, secret_key).list_buckets({}, :params => {:max_keys => 1})
    rescue Aws::Errors::ServiceError, Seahorse::Client::NetworkingError => err
      error_message = err.message
      _log.error("Access/Secret authentication failed: #{err.code} #{error_message}")
      raise MiqException::MiqInvalidCredentialsError, error_message
    end

    true
  end

  def self.verify_iam(crn, api_key)
    begin
      require "ibm_cloud_iam"
      iam_token_api = IbmCloudIam::TokenOperationsApi.new
      token = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)
    rescue IbmCloudIam::ApiError => err
      error_message = err.message
      _log.error("IAM authentication failed: #{err.code} #{error_message}")
      raise MiqException::MiqInvalidCredentialsError, error_message
    end

    require "ibm_cloud_resource_controller"
    authenticator = IbmCloudResourceController::Authenticators::BearerTokenAuthenticator.new(:bearer_token => token.access_token)
    resource_controller_api = IbmCloudResourceController::ResourceControllerV2.new(:authenticator => authenticator)

    begin
      resource_controller_api.get_resource_instance(:id => crn).result
    rescue IbmCloudResourceController::ApiException => err
      _log.error("GUID resource lookup failed: #{err.code} #{err.error}")
      raise MiqException::MiqInvalidCredentialsError, err.error
    end

    true
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

  def remove_object(bucket_name, object_name)
    connect.delete_object(:bucket => bucket_name, :key => object_name)
  end

  def queue_name_for_ems_refresh
    queue_name
  end

  def required_credential_fields(type)
    case type.to_s
    when "default" then %i[auth_key]
    when "bearer"  then %i[password]
    else           []
    end
  end
end
