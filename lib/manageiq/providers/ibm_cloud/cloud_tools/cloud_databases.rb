# frozen_string_literal: true

require 'ibm_cloud_databases'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        class CloudDatabases < Sdk::Branch
          def initialize(cloudtools:, region:)
            super(:cloudtools => cloudtools)
            service_url = "https://api.#{region}.databases.cloud.ibm.com/v5/ibm"
            @sdk_params = {:service_url => service_url}
          end

          # Return a new Cloud Databases SDK instance.
          def sdk_client
            @sdk_params[:authenticator] = @cloudtools.authenticator
            @sdk_client ||= IbmCloudDatabases::CloudDatabasesV5.new(@sdk_params)
          end

          private

          # Create a generator that removes the need for pagination.
          # @param call_back [String] The method name to use for pagination.
          # @param array_key [String] The specific key in the returned array to use.
          #
          # @return [Enumerator] Object to page through results.
          # @yield [Hash] Result of request.
          def each_resource(call_back, array_key: nil, **kwargs, &block)
            start = kwargs[:start]

            loop do
              # Send request.
              response = request(call_back, :start => start, **kwargs)
              array_key = get_common(response.keys) if array_key.nil?

              resources = response.fetch(array_key.to_sym)

              resources&.each(&block)

              return unless response.key?(:next)

              # The :next data structure is a hash with a href member.
              next_url = response.dig(:next, :href)
              return unless next_url

              start = Addressable::URI.parse(next_url).query_values['start']
            end
          end

          #  Try to determine
          def get_common(array_keys)
            keys = array_keys - [:limit, :first, :total_count, :next]
            return keys.first unless keys.empty?

            raise "No array key found in #{array_keys}"
          end
        end
      end
    end
  end
end
