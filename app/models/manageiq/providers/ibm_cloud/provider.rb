class ManageIQ::Providers::IbmCloud::Provider < ::Provider
  has_many :power_virtual_servers_cloud_managers,
           :foreign_key => "provider_id",
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager",
           :inverse_of  => :provider,
           :dependent   => :destroy

  def self.params_for_create
    {
      :fields => [
        {
          :component   => "select",
          :id          => "provider_id",
          :name        => "provider_id",
          :label       => _("IBM Cloud Provider"),
          :isClearable => true,
          :options     => Rbac.filtered(ManageIQ::Providers::IbmCloud::Provider.all).pluck(:name, :id).map do |name, id|
            {
              :label => name,
              :value => id.to_s,
            }
          end
        },
        {
          :component  => "password-field",
          :name       => "authentications.default.auth_key",
          :id         => "authentications.default.auth_key",
          :label      => _("IBM Cloud API Key (if not using an existing provider)"),
          :type       => "password",
          :isRequired => true,
          :condition  => {
            :when    => "provider_id",
            :isEmpty => true
          },
          :validate   => [{:type => "required"}]
        }
      ],
    }
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

  def verify_credentials(auth_type = nil, _options = {})
    !!self.class.raw_connect(authentication_key(auth_type))
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
