# frozen_string_literal: true

require 'ibm_cloud_resource_controller'

%w[controller manager].each { |mod| require_relative File.join('resource_controller', mod) }

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        # CloudTools wrapper class to enhance the IBM Tagging SDK.
        class ResourceController
          def initialize(cloudtools:)
            @cloudtools = cloudtools
          end

          attr_reader :cloudtools

          # Interface for logging.
          # @return [Logger]
          def logger
            @cloudtools.logger
          end

          def controller
            Controller.new(:cloudtools => @cloudtools)
          end

          def manager
            Manager.new(:cloudtools => @cloudtools)
          end
        end
      end
    end
  end
end
