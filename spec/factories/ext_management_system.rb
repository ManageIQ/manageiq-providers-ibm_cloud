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
  factory :ems_ibm_cloud_vpc_network,
          :class  => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager",
          :parent => :ems_cloud
end

FactoryBot.define do
  factory :ems_ibm_cloud_object_storage_storage,
          :class  => "ManageIQ::Providers::IbmCloud::ObjectStorage::StorageManager",
          :parent => :ems_storage
end

FactoryBot.define do
  factory :ems_ibm_cloud_iks, :class => "ManageIQ::Providers::IbmCloud::ContainerManager", :parent => :ems_container do
    provider_region { "ca-tor" }
  end

  factory :ems_ibm_cloud_iks_with_vcr_authentication, :parent => :ems_ibm_cloud_iks do
    after(:create) do |ems|
      api_key = VcrSecrets.iks.api_key

      ems.default_endpoint.update!(
        :hostname          => VcrSecrets.iks.hostname,
        :port              => VcrSecrets.iks.port,
        :security_protocol => "ssl-without-validation"
      )

      ems.authentications << FactoryBot.create(
        :authentication,
        :authtype => "bearer",
        :auth_key => api_key
      )
    end
  end
end
