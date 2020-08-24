class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ProvisionWorkflow < ::MiqProvisionCloudWorkflow
  TIMEZONES = 
  {
    '006' => '(UTC-07:00) US Mountain Standard Time',
  }.freeze

  def self.provider_model
    ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager
  end

  def self.default_dialog_file
    'miq_provision_ibm_dialogs_template'
  end

  def get_timezones(_options = {})
    TIMEZONES
  end

  def allowed_subnets(_options = {})
    ems = resources_for_ui[:ems]
    ar_ems = load_ar_obj(ems) if ems
    ar_subnets = ar_ems.cloud_subnets if ar_ems
    subnets = ar_subnets&.collect { |subnet| [subnet[:ems_ref], subnet[:name]] }
    Hash[subnets || {}]
  end

  private

  def dialog_name_from_automate(_message = 'get_dialog_name')
  end
end
