# frozen_string_literal: true

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Common
          # A class that standardises the timeout for all object.
          class Timeout
            def initialize(global: 60)
              @global = global
            end

            # Set a global timeout.
            attr_accessor :global

            # Set individual timeouts on read, write and connect operations.
            # @return [Timeout]
            def operations(read: 0, write: 0, connect: 0)
              @per_operation = {:read => read, :write => write, :connect => connect}
              self
            end

            # Convert settings to hash.
            # @return [Hash]
            def to_hash
              return {:global => @global} if @per_operation.nil?

              {:per_operation => @per_operation}
            end
          end
        end
      end
    end
  end
end
