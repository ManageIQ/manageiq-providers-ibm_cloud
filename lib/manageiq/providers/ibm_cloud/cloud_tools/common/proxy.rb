# frozen_string_literal: true

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Common
          # Set proxy configurations dynamically.
          class Proxy
            ACCESSOR_KEYS = %i[address port username password headers].freeze
            attr_accessor(*ACCESSOR_KEYS)

            # Add a server configuration.
            # @return [Proxy]
            def server(address:, port:)
              @address = address
              @port = port
              self
            end

            # Add a proxy authentication to the server configuration.
            # @return [Proxy]
            def authentication(username:, password:)
              @username = username
              @password = password
              self
            end

            # Convert non-nil keys into a hash.
            # @return [Hash]
            def to_hash
              self.class::ACCESSOR_KEYS.each_with_object({}) { |key, obj| obj[key] = instance_variable_get("@#{key}") }.compact
            end
          end
        end
      end
    end
  end
end
