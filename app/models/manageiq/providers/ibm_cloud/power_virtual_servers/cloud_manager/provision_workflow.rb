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
    # TODO: replace with api provided values, once issue '114' is solved and merged
    {0 => "s922", 1 => "e880"}
  end

  def allowed_storage_type(_options = {})
    # TODO: replace with api provided values, once issue '115' is solved and merged
    {0 => "None", 1 => "Tier 1", 2 => "Tier 3"}
  end

  def allowed_guest_access_key_pairs(_options = {})
    ar_ems = ar_ems_get
    ar_key_pairs = ar_ems&.key_pairs
    key_pairs = ar_key_pairs&.map&.with_index { |key_pair, i| [i + 1, key_pair['name']] }
    none = [0, 'None']
    Hash[key_pairs&.insert(0, none) || none]
  end

  def allowed_subnets(_options = {})
    ar_ems = ar_ems_get
    ar_subnets = ar_ems&.cloud_subnets
    subnets = ar_subnets&.collect { |subnet| [subnet[:ems_ref], subnet[:name]] }
    Hash[subnets || {}]
  end

  def allowed_cloud_volumes(_options = {})
    ar_ems = ar_ems_get
    ar_volumes = ar_ems&.cloud_volumes if ar_ems
    cloud_volumes = ar_volumes&.map { |cloud_volume| [cloud_volume['ems_ref'], cloud_volume['name']] }
    Hash[cloud_volumes || {}]
  end

  def set_request_values(values)
    values[:new_volumes] = parse_new_volumes_fields(values)
    super
  end

  def parse_new_volumes_fields(values)
    stop = false
    new_volumes = []

    while not stop
      new_volume = {}

      %w(name size diskType shareable).map do |fld|
        cnt = new_volumes.length+1
        key = (:"#{fld}_#{cnt}").to_sym
        new_volume[fld.to_sym] = values[key] if values.key?(key)
      end

      stop = new_volume.empty?

      if not stop
        new_volume[:name] = nil if new_volume[:name].blank?
        new_volume[:diskType] = nil if new_volume[:diskType].blank?
        new_volume[:size] = new_volume[:size].blank? ? nil : new_volume[:size].to_i
        new_volume[:shareable] = ['null', nil].exclude?(new_volume[:shareable])
        new_volumes << new_volume
      end
    end

    new_volumes
  end

  def validate_entitled_processors(field, values, dlg, fld, value)
    dedicated = values[:instance_type][1] == 'dedicated'

    fval = value.match(/^\s*[\d]+(\.[\d]+)?\s*$/) ? value.strip.to_f : 0
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

  def ar_ems_get
    ems = resources_for_ui[:ems]
    ems ? load_ar_obj(ems) : nil
  end

  def dialog_name_from_automate(_message = 'get_dialog_name')
  end
end
