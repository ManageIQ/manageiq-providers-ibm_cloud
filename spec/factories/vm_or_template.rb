FactoryBot.define do
  factory :vm_ibm_cloud_power_virtual_servers, :class => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm", :parent => :vm_cloud do
    vendor { "ibm" }

    trait :with_provider do
      after(:create) do |x|
        FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :vms => [x])
      end
    end
  end

  factory :template_ibm_cloud_power_virtual_servers, :class => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template", :parent => :template_cloud do
    vendor { "ibm" }
  end

  factory :vm_ibm_cloud_vpc, :class => "ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm", :parent => :vm_cloud do
    vendor { "ibm" }

    trait :with_provider do
      after(:create) do |x|
        FactoryBot.create(:ems_ibm_cloud_vpc, :vms => [x])
      end
    end
  end

  factory :template_ibm_cloud_vpc, :class => "ManageIQ::Providers::IbmCloud::VPC::CloudManager::Template", :parent => :template_cloud do
    vendor { "ibm" }
  end
end
