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
            # Some of the list methods look like they have pagination properties but the default SDK doesn't allow passing in the start argument.
            # @param call_back [String] The method name to use for pagination.
            # @param kwargs [Hash{Symbol => String, Number}] Key pairs to be passed into the request.
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
