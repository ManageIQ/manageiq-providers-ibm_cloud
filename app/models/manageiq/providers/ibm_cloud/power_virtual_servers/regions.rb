class ManageIQ::Providers::IbmCloud::PowerVirtualServers::Regions < ManageIQ::Providers::Regions
  class << self
    private

    def ems_type
      :ibm_cloud_power_virtual_servers
    end

    def regions_yml
      ManageIQ::Providers::IbmCloud::Engine.root.join("config/power_virtual_servers_regions.yml")
    end
  end
end
