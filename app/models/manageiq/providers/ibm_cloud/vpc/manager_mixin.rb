module ManageIQ::Providers::IbmCloud::VPC::ManagerMixin
  extend ActiveSupport::Concern

  def required_credential_fields(_type)
    [:auth_key]
  end

  def supported_auth_attributes
    %w[auth_key]
  end

  # Return a cloudtools vpc object.
  # @param options [Hash] Hash of options. Default to an empty Hash.
  # @return [ManageIQ::Providers::IbmCloud::CloudTools::Vpc]
  def connect(options = {})
    key = authentication_key(options[:auth_type])
    region = options[:provider_region] || provider_region
    sdk = self.class.raw_connect(key)
    sdk.vpc(:region => region)
  end

  # Same as calling connect.
  # @param _auth_type [nil] Not used
  # @param options [Hash] Connection options.
  # @return [ManageIQ::Providers::IbmCloud::CloudTools::Vpc]
  def verify_credentials(_auth_type = nil, options = {})
    connect(options).cloudtools.authenticator
  end

  module ClassMethods
    def params_for_create
      @params_for_create ||= {
        :fields => [
          {
            :component    => "select",
            :id           => "provider_region",
            :name         => "provider_region",
            :label        => _("Region"),
            :isRequired   => true,
            :includeEmpty => true,
            :validate     => [{:type => "required"}],
            :options      => provider_region_options
          },
          {
            :component => 'sub-form',
            :name      => 'endpoints-subform',
            :title     => _("Endpoint"),
            :fields    => [
              {
                :component              => 'validate-provider-credentials',
                :name                   => 'authentications.default.valid',
                :skipSubmit             => true,
                :isRequired             => true,
                :validationDependencies => %w[type zone_id provider_region],
                :fields                 => [
                  {
                    :component  => "password-field",
                    :name       => "authentications.default.auth_key",
                    :label      => _("IBM Cloud API Key"),
                    :type       => "password",
                    :isRequired => true,
                    :validate   => [{:type => "required"}]
                  },
                ],
              },
            ],
          },
        ],
      }.freeze
    end

    # Get the authentication from for args hash.
    # args:
    # {
    #   "uid_ems"         => "",
    #   "authentications" => {
    #     "default" => {
    #       "auth_key" => "",
    #     }
    #   }
    # }
    # @param args [Hash] The supplied arguments.
    # @return [String] The retrieved authorization key.
    def auth_key(args)
      auth_key = args.dig('authentications', 'default', 'auth_key')
      auth_key = ManageIQ::Password.try_decrypt(auth_key)
      auth_key ||= find(args['id']).authentication_token('default')
      auth_key
    end

    # Verify that the credentials can be authenitcted by IAM.
    # @see auth_key
    # @raise [MiqException::MiqInvalidCredentialsError] The authentication failed.
    def verify_credentials(args)
      raw_connect(auth_key(args))&.authenticator
    rescue IBMCloudSdkCore::ApiException => err
      raise MiqException::MiqInvalidCredentialsError, _(err)
    end

    # Get a new CloudTools class.
    # @raise [MiqException::MiqInvalidCredentialsError] The apikey is nil.
    # @return [ManageIQ::Providers::IbmCloud::CloudTools] An instantiated version of the CloudTools.
    def raw_connect(api_key)
      ManageIQ::Providers::IbmCloud::CloudTool.new(:api_key => api_key)
    rescue RuntimeError
      raise MiqException::MiqInvalidCredentialsError, _('Missing credentials')
    end
  end
end
