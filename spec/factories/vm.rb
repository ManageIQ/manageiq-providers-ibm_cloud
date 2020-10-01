FactoryBot.define do
  factory :vm_ibm_cloud_power_virtual_servers, :class => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm", :parent => :vm_cloud do
    vendor { "ibm" }

    trait :with_provider do
      after(:create) do |x|
        FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :vms => [x])
      end
    end
  end
end
