require 'yaml'

module ManageIQ
  module Providers::IbmCloud::VPC
    module Regions
      REGIONS = YAML.load_file(
        ManageIQ::Providers::IbmCloud::Engine.root.join('db/fixtures/ibm_cloud_vpc_regions.yml')
      ).each_value(&:freeze).freeze

      def self.regions
        REGIONS
      end

      def self.regions_by_hostname
        regions.values.index_by { |v| v[:hostname] }
      end

      def self.all
        regions.values
      end

      def self.names
        regions.keys
      end

      def self.hostnames
        regions_by_hostname.keys
      end

      def self.find_by_name(name)
        regions[name]
      end

      def self.find_by_hostname(hostname)
        regions_by_hostname[hostname]
      end
    end
  end
end
