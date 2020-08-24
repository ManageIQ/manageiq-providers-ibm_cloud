FactoryBot.define do
  factory :ems_ibm_cloud_power_virtual_servers_cloud,
          :aliases => ["manageiq/providers/ibm_cloud_power_virtual_servers/cloud_manager"],
          :class   => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager",
          :parent  => :ems_cloud
end
