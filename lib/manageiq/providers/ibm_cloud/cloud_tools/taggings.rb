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
          # Override client method to handle configuration for the new SDK
          def client
            sdk_client.tap do |client|
              # Configure proxy if present
              if @cloudtools.proxy.to_hash[:address]
                proxy_hash = @cloudtools.proxy.to_hash
                client.api_client.config.scheme = 'http'
                client.api_client.config.host = "#{proxy_hash[:address]}:#{proxy_hash[:port]}"
              end

              # Configure timeout if present
              timeout_hash = @cloudtools.timeout.to_hash
              client.api_client.config.timeout = timeout_hash[:timeout] if timeout_hash[:timeout]
            end
          end

          # Override request method to handle the new SDK's response format
          # The new SDK returns model objects directly, not wrapped in a .result property
          def request(call_back, **)
            request = send_request(call_back, **)
            return if request.nil?

            # The new SDK returns the model object directly
            # Convert it to a hash using to_hash if available, otherwise use JSON conversion
            if request.respond_to?(:to_hash)
              request.to_hash
            else
              JSON.parse(request.to_json, :symbolize_names => true)
            end
          end

          private

          # Return a GlobalTagging SDK instance. Requires an internet connection.
          # @return [IbmCloudGlobalTagging::TagsApi]
          def sdk_client
            # This is called by the parent's client method, but we override client
            # so this won't be used. Keeping for compatibility.
            config = IbmCloudGlobalTagging::Configuration.new
            config.access_token = @cloudtools.authenticator.bearer_info[:token]

            api_client = IbmCloudGlobalTagging::ApiClient.new(config)
            IbmCloudGlobalTagging::TagsApi.new(api_client)
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
