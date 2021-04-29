FactoryBot.define do
  factory :ems_ibm_cloud_power_virtual_servers_cloud,
          :aliases => ["manageiq/providers/ibm_cloud_power_virtual_servers/cloud_manager"],
          :class   => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager",
          :parent  => :ems_cloud
end

FactoryBot.define do
  factory :ems_ibm_cloud_power_virtual_servers_storage,
          :aliases => ["manageiq/providers/ibm_cloud_power_virtual_servers/storage_manager"],
          :class   => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager",
          :parent  => :ems_cloud
end

FactoryBot.define do
  factory :ems_ibm_cloud_vpc,
          :class  => "ManageIQ::Providers::IbmCloud::VPC::CloudManager",
          :parent => :ems_cloud
end

FactoryBot.define do
  factory :ems_ibm_cloud_object_storage_object,
          :class  => "ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager",
          :parent => :ems_storage
end
