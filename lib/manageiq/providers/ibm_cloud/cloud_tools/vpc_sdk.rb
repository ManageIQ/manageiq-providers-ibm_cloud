# frozen_string_literal: true

require 'ibm_vpc'

dir_name = File.basename(__FILE__).split('.')[0]
Dir.glob(File.join(dir_name, '*.rb'), :base => File.dirname(__FILE__)) { |req| require_relative req }

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        # Collect all classes used by the Vpc class.
        module VpcSdk
        end
      end
    end
  end
end
