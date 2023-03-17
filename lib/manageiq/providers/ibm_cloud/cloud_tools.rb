# frozen_string_literal: true

require 'ibm_vpc'

require_relative 'cloud_tools/sdk'
dir_name = File.basename(__FILE__).split('.')[0]
Dir.glob(File.join(dir_name, '*.rb'), :base => File.dirname(__FILE__)) { |req| require_relative req }

module ManageIQ
  module Providers
    module IbmCloud
      # Collect SDKs and tools into a single place.
      module CloudTools
      end
    end
  end
end
