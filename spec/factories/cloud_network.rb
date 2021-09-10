FactoryBot.define do
  factory :cloud_network_ibm_cloud_vpc,
          :class  => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudNetwork",
          :parent => :cloud_network
end
