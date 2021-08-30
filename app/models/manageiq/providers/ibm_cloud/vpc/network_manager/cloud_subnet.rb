class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet < ::CloudSubnet
  include ProviderObjectMixin

  supports :create
  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete, _("The subnet is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
    if number_of(:vms) > 0
      unsupported_reason_add(:delete, _("The subnet has an active %{table}") % {
        :table => ui_lookup(:table => "vm_cloud")
      })
    end
  end

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component    => 'select',
          :name         => 'cloud_network_id',
          :id           => 'cloud_network_id',
          :label        => _('Network'),
          :isRequired   => true,
          :includeEmpty => true,
          :validate     => [{:type => 'required'}],
          :options      => ems.cloud_networks.map do |cvt|
            {
              :label => cvt.name,
              :value => cvt.id,
            }
          end
        }
      ]
    }
  end

  def self.raw_create_cloud_subnet(ext_management_system, options)
    cloud_network = CloudNetwork.find_by(:id => options[:cloud_network_id]) if options[:cloud_network_id]

    subnet = {
      :vpc             => {
        :id => cloud_network&.ems_ref
      },
      :name            => options[:name],
      :ipv4_cidr_block => options[:cidr]
    }

    ext_management_system.with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:create_subnet, :subnet_prototype => subnet)
    end
  rescue => err
    _log.error("subnet=[#{options[:name]}], error: #{err}")
    raise
  end

  def raw_delete_cloud_subnet
    with_provider_connection do |connection|
      connection.vpc(:region => ext_management_system.parent_manager.provider_region)
                .request(:delete_subnet, :id => ems_ref)
    end
  rescue => err
    _log.error("subnet=[#{name}], error: #{err}")
    raise
  end
end
