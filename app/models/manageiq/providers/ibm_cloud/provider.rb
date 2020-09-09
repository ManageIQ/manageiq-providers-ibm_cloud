class ManageIQ::Providers::IbmCloud::Provider < ::Provider
  has_many :power_virtual_servers_cloud_managers,
           :foreign_key => "provider_id",
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager",
           :inverse_of  => :provider,
           :dependent   => :destroy

  def self.params_for_create
    @params_for_create ||= {
      :fields => [
        {
          :component  => "password-field",
          :name       => "authentications.default.auth_key",
          :id         => "authentications.default.auth_key",
          :label      => _("IBM Cloud API Key"),
          :type       => "password",
          :isRequired => true,
          :validate   => [{:type => "required"}]
        }
      ],
    }.freeze
  end

  def self.verify_credentials(args)
    auth_key = args.dig("authentications", "default", "auth_key")
    auth_key = MiqPassword.try_decrypt(auth_key)
    auth_key ||= find(args["id"]).authentication_token('default')

    !!raw_connect(auth_key)
  end

  def self.raw_connect(api_key)
    raise MiqException::MiqInvalidCredentialsError, _("Missing credentials") if api_key.blank?

    require "ibm-cloud-sdk"
    iam = IBM::Cloud::SDK::IAM.new(api_key)
    iam.get_identity_token
  end

  def required_credential_fields(_type)
    [:auth_key]
  end

  def supported_auth_attributes
    %w[auth_key]
  end

  def name=(val)
    super(val.sub(/ (Power Virtual Servers)$/, ''))
  end
end
