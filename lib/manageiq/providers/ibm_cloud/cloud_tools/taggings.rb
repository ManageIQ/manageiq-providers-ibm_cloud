# frozen_string_literal: true

require 'ibm_cloud_global_tagging'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        # Module to hold any tagging SDK specific classes.
        module GlobalTags
        end

        # CloudTools wrapper class to enhance the IBM Tagging SDK.
        class GlobalTag < Sdk::Branch
          private

          # Return a GlobalTagging SDK instance. Requires an internet connection.
          # @return [IbmCloudGlobalTagging::GlobalTaggingV1]
          def sdk_client
            IbmCloudGlobalTagging::GlobalTaggingV1.new(:authenticator => @cloudtools.authenticator)
          end

          # Create a generator that removes the need for pagination.
          # @param call_back [String] The method name to use for pagination.
          # @param array_key [String] The specific key in the returned array to use.
          #
          # @return [Enumerator] Object to page through results.
          # @yield [Hash] Result of request.
          def each_resource(call_back, **kwargs)
            offset = kwargs[:offset].nil? ? 0 : kwargs[:offset]

            loop do
              response = request(call_back, :offset => offset, **kwargs)
              offset = response.fetch(:offset) + response.fetch(:limit)

              resources = response[:items]
              resources&.each { |value| yield value }

              return if resources.empty?
            end
          end
        end
      end
    end
  end
end
