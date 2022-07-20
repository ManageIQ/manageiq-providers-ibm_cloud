module ManageIQ::Providers::IbmCloud::VPC::ManagerMixin
  extend ActiveSupport::Concern

  def required_credential_fields(_type)
    [:auth_key]
  end

  def supported_auth_attributes
    %w[auth_key]
  end

  # Return a cloudtools object.
  # @param options [Hash] Hash of options. Default to an empty Hash.
  # @return [ManageIQ::Providers::IbmCloud::CloudTools::Vpc] or
  # [ManageIQ::Providers::IbmCloud::CloudTools::ActivityTracker]
  def connect(options = {})
    key = authentication_key(options[:auth_type])
    self.class.raw_connect(key)
  end

  # Same as calling connect.
  # @param auth_type [nil]
  # @param options [Hash] Connection options.
  # @return [ManageIQ::Providers::IbmCloud::CloudTools::Vpc] or [Boolean]
  def verify_credentials(auth_type = nil, options = {})
    case auth_type&.to_sym
    when :events
      verify_events_credentials(options)
    else
      verify_default_credentials(options)
    end
  end

  def verify_default_credentials(options = {})
    connect(options).authenticator
  end

  def verify_events_credentials(options = {})
    service_key = authentication_key("events")
    connect(options).resource.controller.collection(:list_resource_keys).any? { |key| key.dig(:credentials, :service_key) == service_key }
  end

  module ClassMethods
    def params_for_create
      {
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
                    }
                  ]
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
                          :label => _('Enabled'),
                          :value => 'enable_metrics',
                        },
                      ],
                    },
                    {
                      :component  => 'password-field',
                      :id         => 'endpoints.metrics.options.monitoring_instance_id',
                      :name       => 'endpoints.metrics.options.monitoring_instance_id',
                      :label      => _('IBM Cloud Monitoring Instance GUID'),
                      :isRequired => true,
                      :condition  => {
                        :when => "metrics_selection",
                        :is   => 'enable_metrics',
                      },
                    },
                  ]
                },
                {
                  :component => 'tab-item',
                  :id        => 'events-tab',
                  :name      => 'events-tab',
                  :title     => _('Events'),
                  :fields    => [
                    {
                      :component    => 'protocol-selector',
                      :id           => 'events_selection',
                      :name         => 'events_selection',
                      :skipSubmit   => true,
                      :initialValue => 'none',
                      :label        => _('Type'),
                      :options      => [
                        {
                          :label => _('Disabled'),
                          :value => 'none',
                        },
                        {
                          :label => _('Enabled'),
                          :value => 'enable_events',
                        },
                      ],
                    },
                    {
                      :component  => 'password-field',
                      :id         => 'authentications.events.auth_key',
                      :name       => 'authentications.events.auth_key',
                      :label      => _('IBM Cloud Activity Tracker Instance Service Key'),
                      :isRequired => true,
                      :condition  => {
                        :when => "events_selection",
                        :is   => 'enable_events',
                      },
                    },
                  ]
                }
              ]
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
      raise MiqException::MiqInvalidCredentialsError, err.error
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
