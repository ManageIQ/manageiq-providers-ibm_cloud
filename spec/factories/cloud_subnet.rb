FactoryBot.define do
  factory :cloud_subnet_ibm_cloud_vpc,
          :class  => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet",
          :parent => :cloud_subnet
end
