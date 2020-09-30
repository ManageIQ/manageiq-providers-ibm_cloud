FactoryBot.define do
  factory :ems_ibm_cloud_power_virtual_servers_storage,
          :aliases => ["manageiq/providers/ibm_cloud_power_virtual_servers/storage__manager"],
          :class   => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager",
          :parent  => :ems_cloud
end

FactoryBot.define do
  factory :ems_ibm_cloud_vpc,
          :class  => "ManageIQ::Providers::IbmCloud::VPC::CloudManager",
          :parent => :ems_cloud
end
