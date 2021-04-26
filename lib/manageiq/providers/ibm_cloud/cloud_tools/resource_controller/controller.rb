# frozen_string_literal: true

require_relative 'common'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        class ResourceController
          # CloudTools wrapper class to enhance the IBM Resource Controller Resource Manager SDK.
          class Controller < Common
            private

            # Return a ResourceController SDK instance. Requires an internet connection.
            # @return [IbmCloudResourceController::ResourceControllerV2]
            def sdk_client
              IbmCloudResourceController::ResourceControllerV2.new(:authenticator => @cloudtools.authenticator)
            end
          end
        end
      end
    end
  end
end
