require 'ipaddr'

class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ProvisionWorkflow < ::MiqProvisionCloudWorkflow
  TIMEZONES =
    {
      '006' => '(UTC-07:00) US Mountain Standard Time',
    }.freeze

  def self.provider_model
    ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager
  end

  def get_timezones(_options = {})
    TIMEZONES
  end

  def volume_dialog_keys
    %i[name size shareable]
  end

  def template_id
    values&.dig(:src_vm_id, 0)
  end

  def vm_image
    @vm_image ||= begin
      template_id = values&.dig(:src_vm_id, 0)
      ar_ems.miq_templates.find_by(:id => template_id)
    end
  end

  def sap_image?
    !template_id.nil? && vm_image.description == 'stock-sap'
  end

  def sap_flavor
    if sap_image?
      begin
        selected_flavor_name = values&.dig(:sys_type, 1)
        ar_ems.flavors.find_by(:name => selected_flavor_name)
      end
    end
  end

  def sap_flavor_memory(_options = {})
    if sap_flavor
      {"2" => (sap_flavor.memory / 1.0.gigabyte).to_i}
    end
  end

  def sap_flavor_cpus(_options = {})
    if sap_flavor
      {sap_flavor.cpus.to_s => ''}
    end
  end

  def allowed_instance_type(_options = {})
    return {} if ar_ems.nil?

    if sap_image?
      {
        0 => "dedicated"
      }
    else
      {
        0 => "capped",
        1 => "shared",
        2 => "dedicated"
      }
    end
  end

  def allowed_sys_type(_options = {})
    return {} if ar_ems.nil?

    flavor_type = "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::#{sap_image? ? 'SAPProfile' : 'SystemType'}"

    ar_sys_types = ar_ems.flavors.find_all { |flavor| flavor.type == flavor_type }

    sys_types = ar_sys_types&.map&.each_with_index { |sys_type, i| [i, sys_type['name']] }
    Hash[sys_types || {}]
  end

  def allowed_storage_type(_options = {})
    return {} if ar_ems.nil?

    ar_storage_types = ar_ems.cloud_volume_types
    storage_types = ar_storage_types&.map&.each_with_index { |storage_type, i| [i, storage_type['name']] }
    Hash[storage_types || none]
  end

  def allowed_guest_access_key_pairs(_options = {})
    return {} if ar_ems.nil?

    ar_key_pairs = ar_ems.key_pairs
    key_pairs = ar_key_pairs&.map&.with_index(1) { |key_pair, i| [i, key_pair['name']] }
    none = [0, 'None']
    Hash[key_pairs&.insert(0, none) || none]
  end

  def allowed_subnets(_options = {})
    return {} if ar_ems.nil?

    ar_subnets = ar_ems.cloud_subnets
    subnets = ar_subnets&.collect { |subnet| [subnet[:ems_ref], subnet[:name]] }
    none = ['None', 'None (Must attach to new public network)']
    Hash[subnets.unshift(none)]
  end

  def allowed_cloud_volumes(_options = {})
    return {} if ar_ems.nil?

    storage_type = values&.dig(:storage_type, 1)

    ar_volumes = ar_ems.cloud_volumes.select do |cloud_volume|
      cloud_volume['volume_type'] == storage_type &&
        (cloud_volume['multi_attachment'] || cloud_volume['status'] == 'available')
    end

    cloud_volumes = ar_volumes&.map { |cloud_volume| [cloud_volume['ems_ref'], cloud_volume['name']] }

    Hash[cloud_volumes || {}]
  end

  def allowed_placement_groups(_options = {})
    return {} if ar_ems.nil?

    ar_ems.placement_groups.to_h { |group| [group.ems_ref, "#{group.policy}: #{group.name}"] }
  end

  def allowed_shared_processer_pools(_options = {})
    return {} if ar_ems.nil?

    ar_ems.resource_pools.to_h { |pool| [pool.ems_ref, pool.name] }
  end

  def set_request_values(values)
    values[:new_volumes] = parse_new_volumes_fields(values)
    super
  end

  def parse_new_volumes_fields(values)
    new_volumes = []
    storage_type = values[:storage_type][1]

    values.select { |k, _v| k =~ /(#{volume_dialog_keys.join("|")})_(\d+)/ }.each do |key, value|
      field, cnt = key.to_s.split("_")
      cnt = Integer(cnt)

      new_volumes[cnt] ||= {}
      new_volumes[cnt][field.to_sym] = value
    end

    new_volumes.drop(1).map! do |new_volume|
      new_volume[:size] = new_volume[:size].to_i
      new_volume[:shareable] = [nil, 'null'].exclude?(new_volume[:shareable])
      new_volume[:disk_type] = storage_type
      new_volume
    end
  end

  def validate_entitled_processors(_field, values, _dlg, _fld, value)
    dedicated = values[:instance_type][1] == 'dedicated'

    fval = /^\s*[\d]*(\.[\d]+)?\s*$/.match?(value) ? value.strip.to_f : 0
    return _("Entitled Processors field does not contain a well-formed positive number") unless fval > 0

    if dedicated
      return _('For dedicated processors, the format is: "positive integer"') unless (fval % 1).zero?
    else
      return _('For shared processors, the format is: "positive whole multiple of 0.25"') unless ((fval / 0.25) % 1).zero?
    end
  end

  def validate_pin_policy(_field, _values, _dlg, _fld, value)
    return _('VM pinning policy can only be none, soft, or hard') unless ['none', 'soft', 'hard'].include?(value)
  end

  def validate_ip_address(_field, _values, _dlg, _fld, value)
    return if value.blank?

    begin
      valid = IPAddr.new(value.strip).ipv4?
    rescue IPAddr::InvalidAddressError
      valid = false
    end

    return _('IP-address field has to be either blank or a valid IPv4 address') unless valid
  end

  def validate_placement_group(_filed, _values, _dlg, _fld, value)
    return if value.blank?

    placement_group = ar_ems.placement_groups.find_by!(:ems_ref => value)
    vms_in_placement_group = placement_group.vms

    # If policy is affinity, check to make sure the new vm has the same flavor as all the members of the group
    valid = if placement_group[:policy] == 'affinity' && vms_in_placement_group.present?
              vms_in_placement_group.first.flavor.name == values&.dig(:sys_type, 1)
            else
              true
            end
    _('Invalid placement group - incompatible colocation policy') unless valid
  end

  def validate_shared_processer_pool(_filed, _values, _dlg, _fld, value)
    return if value.blank?

    resource_pool = ar_ems.resource_pools.find_by!(:ems_ref => value)
    vms_in_resource_pool = resource_pool.vms
    # We don't save a processor pool machine type in the db, so there is no way to validate an empty processor pool
    return if vms_in_resource_pool.blank?

    # Shared processor pools are used and shared by a set of virtual server instances of the same machine type (host).
    valid = vms_in_resource_pool.first.flavor.name == values&.dig(:sys_type, 1)
    _('Invalid processor pool - incompatible machine type (host)') unless valid
  end

  private

  def ar_ems
    rui = resources_for_ui[:ems]
    ems = load_ar_obj(rui) if rui

    ems
  end

  def dialog_name_from_automate(message = 'get_dialog_name')
    super(message, {'platform' => 'ibm_powervs'})
  end
end
