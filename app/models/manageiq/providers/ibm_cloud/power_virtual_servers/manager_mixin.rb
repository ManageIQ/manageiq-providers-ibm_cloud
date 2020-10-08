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
    creds = self.class.raw_connect(auth_key, uid_ems)

    options[:service] ||= "PowerIaas"
    case options[:service]
    when "PowerIaas"
      region, guid, token, crn, tenant = creds.values_at(:region, :guid, :token, :crn, :tenant)
      IBM::Cloud::SDK::PowerIaas.new(region, guid, token, crn, tenant)
    else
      raise ArgumentError, "Unknown target API set: '#{options[:service]}''"
    end
  end

  def verify_credentials(_auth_type = nil, options = {})
    connect(options)
    true
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
                }
              ]
            ]
          }
        ]
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

      require "ibm-cloud-sdk"
      IBM::Cloud::SDK.logger = $ibm_cloud_log
      iam = IBM::Cloud::SDK::IAM.new(api_key)
      begin
        token = iam.get_identity_token
      rescue RestClient::ExceptionWithResponse => e
        _log.error("IAM authentication failed: #{e.response}")
        raise MiqException::MiqInvalidCredentialsError, JSON.parse(e.response)['errorMessage']
      end

      begin
        power_iaas_service = IBM::Cloud::SDK::ResourceController.new(token).get_resource(pcloud_guid)
      rescue RestClient::ExceptionWithResponse => e
        _log.error("GUID resource lookup failed: #{e.response}")
        raise MiqException::MiqInvalidCredentialsError, JSON.parse(e.response)['message']
      end

      {:token => token, :guid => pcloud_guid, :crn => power_iaas_service.crn, :region => power_iaas_service.region_id, :tenant => power_iaas_service.account_id}
    end
  end
end
