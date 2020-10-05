require 'ipaddr'

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

  def allowed_sys_type(_options = {})
    ar_sys_types = ar_ems.flavors
    sys_types = ar_sys_types&.map&.with_index(1) { |sys_type, i| [i, sys_type['name']] }
    Hash[sys_types || {}]
  end

  def allowed_storage_type(_options = {})
    # TODO: replace with api provided values, once issue '115' is solved and merged
    {0 => "None", 1 => "Tier 1", 2 => "Tier 3"}
  end

  def allowed_guest_access_key_pairs(_options = {})
    ar_key_pairs = ar_ems.key_pairs
    key_pairs = ar_key_pairs&.map&.with_index(1) { |key_pair, i| [i, key_pair['name']] }
    none = [0, 'None']
    Hash[key_pairs&.insert(0, none) || none]
  end

  def allowed_subnets(_options = {})
    ar_subnets = ar_ems.cloud_subnets
    subnets = ar_subnets&.collect { |subnet| [subnet[:ems_ref], subnet[:name]] }
    Hash[subnets || {}]
  end

  def allowed_cloud_volumes(_options = {})
    ar_volumes = ar_ems.cloud_volumes
    cloud_volumes = ar_volumes&.map { |cloud_volume| [cloud_volume['ems_ref'], cloud_volume['name']] }
    Hash[cloud_volumes || {}]
  end

  def validate_entitled_processors(_field, values, _dlg, _fld, value)
    dedicated = values[:instance_type][1] == 'dedicated'

    fval = /^\s*[\d]*(\.[\d]+)?\s*$/.match?(value) ? value.strip.to_f : 0
    return "Entitled Processors field does not contain a well-formed positive number" unless fval > 0

    if dedicated
      return 'For dedicated processors, the format is: "positive integer"' unless fval % 1 == 0
    else
      return 'For shared processors, the format is: "positive whole multiple of 0.25"' unless (fval / 0.25) % 1 == 0
    end
  end

  def validate_ip_address(_field, _values, _dlg, _fld, value)
    return if value.blank?

    begin
      valid = IPAddr.new(value.strip).ipv4?
    rescue IPAddr::InvalidAddressError
      valid = false
    end

    return 'IP-address field has to be either blank or a valid IPv4 address' unless valid
  end

  private

  def ar_ems
    rui = resources_for_ui[:ems]
    ems = load_ar_obj(rui) if rui
    raise MiqException::MiqProvisionError, 'A server-side error occurred in the provisioning workflow' if ems.nil?

    ems
  end

  def dialog_name_from_automate(_message = 'get_dialog_name')
  end
end
