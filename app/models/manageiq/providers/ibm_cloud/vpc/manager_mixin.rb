module ManageIQ::Providers::IbmCloud::VPC::ManagerMixin
  extend ActiveSupport::Concern

  def required_credential_fields(_type)
    [:auth_key]
  end

  def supported_auth_attributes
    %w[auth_key]
  end

  def connect(options = {})
    key = authentication_key(options[:auth_type])
    region = options[:provider_region] || provider_region
    token = self.class.raw_connect(key)

    service_url = "https://#{region}.iaas.cloud.ibm.com/v1"
    IbmVpc::VpcV1.new(:version => "2020-08-01", :authenticator => token, :service_url => service_url)
  end

  def verify_credentials(_auth_type = nil, options = {})
    !!connect(options)
  end

  module ClassMethods
    def params_for_create
      @params_for_create ||= {
        :fields => [
          {
            :component  => "select",
            :id         => "provider_region",
            :name       => "provider_region",
            :label      => _("Region"),
            :isRequired => true,
            :validate   => [{:type => "required"}],
            :options    => provider_region_options
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

    # Verify Credentials
    # args:
    # {
    #   "uid_ems"         => "",
    #   "authentications" => {
    #     "default" => {
    #       "auth_key" => "",
    #     }
    #   }
    # }

    def verify_credentials(args)
      auth_key = args.dig('authentications', 'default', 'auth_key')
      auth_key = ManageIQ::Password.try_decrypt(auth_key)
      auth_key ||= find(args['id']).authentication_token('default')

      !!raw_connect(auth_key)
    end

    def raw_connect(api_key)
      if api_key.blank?
        raise MiqException::MiqInvalidCredentialsError, _('Missing credentials')
      end

      require "ibm_cloud_iam"
      iam_token_api = IbmCloudIam::TokenOperationsApi.new
      token = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)

      require "ibm_vpc"
      IbmVpc::Authenticators::BearerTokenAuthenticator.new(:bearer_token => token.access_token)
    end
  end
end
