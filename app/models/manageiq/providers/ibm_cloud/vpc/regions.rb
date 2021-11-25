module ManageIQ
  module Providers::IbmCloud::VPC
    class Regions < ManageIQ::Providers::Regions
      class << self
        private

        def ems_type
          :ems_ibm_cloud_vpc
        end

        def regions_yml
          ManageIQ::Providers::IbmCloud::Engine.root.join("config/vpc_regions.yml")
        end
      end
    end
  end
end
