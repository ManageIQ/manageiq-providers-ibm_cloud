class ManageIQ::Providers::IbmCloud::Provider < ::Provider
  has_many :power_virtual_servers_cloud_managers,
           :foreign_key => "provider_id",
           :class_name  => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager",
           :inverse_of  => :provider,
           :dependent   => :destroy

  def name=(val)
    super(val.sub(/ (Power Virtual Servers)$/, ''))
  end
end
