FactoryBot.define do
  factory :provider_ibm_cloud,
          :aliases => ["manageiq/providers/ibm_cloud/provider"],
          :class   => "ManageIQ::Providers::IbmCloud::Provider",
          :parent  => :provider do
    zone :factory => :zone
  end
end
