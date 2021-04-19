# frozen_string_literal: true

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        class ResourceController
          # CloudTools wrapper class to enhance the IBM Resource Controller Resource Manager SDK.
          class Common < Sdk::Branch
            private

            # Create a generator that removes the need for pagination.
            # @param call_back [String] The method name to use for pagination.
            # @param call_back [String] The method name to use for pagination.
            #
            # @return [Enumerator] Object to page through results.
            # @yield [Hash] Result of request.
            def each_resource(call_back, **kwargs)
              response = request(call_back, **kwargs)
              resources = response[:resources]
              resources.each { |value| yield value }
            end
          end
        end
      end
    end
  end
end
