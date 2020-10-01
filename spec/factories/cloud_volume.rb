FactoryBot.define do
  factory :cloud_volume_ibm_cloud_power_virtual_servers, :class => "ManageIQ::Providers::IbmCloud::PowerVirtualServers::StorageManager::CloudVolume", :parent => :cloud_volume do
    size { 1.gigabyte }
    volume_type { 'tier1' }
  end
end
