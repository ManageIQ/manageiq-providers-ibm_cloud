# frozen_string_literal: true

require_relative 'common'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        class ResourceController
          # CloudTools wrapper class to enhance the IBM Resource Controller Resource Manager SDK.
          class Manager < Common
            private

            # Return a ResourceManager SDK instance. Requires an internet connection.
            # @return [IbmCloudResourceController::ResourceManagerV2]
            def sdk_client
              IbmCloudResourceController::ResourceManagerV2.new(:authenticator => @cloudtools.authenticator)
            end
          end
        end
      end
    end
  end
end
