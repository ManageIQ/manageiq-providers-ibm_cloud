# frozen_string_literal: true

dir_name = File.basename(__FILE__).split('.')[0]
Dir.glob(File.join(dir_name, '*.rb'), :base => File.dirname(__FILE__)) { |req| require_relative req }

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        #  Classes that provide a common framework for CloudTool derived classes.
        module Common
        end
      end
    end
  end
end
