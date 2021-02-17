# frozen_string_literal: true

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Sdk
          # Class that provides template for classes that deal with a specific subject of the API.
          # @param parent [Branch] An instantiated Branch object.
          class Leaf
            def initialize(parent:)
              @parent = parent
            end

            # A logger object.
            def logger
              @parent.logger
            end

            # Wait for the VM instance to be in a stable state.
            # @param sleep_time [Integer] The time to sleep between refreshes.
            # @param timeout [Integer] The number of seconds before raising an error.
            # @param block [Proc] A block to test against. Must return a boolean.
            # @return [Array] Status of operation and informational message.
            def wait_for(sleep_time: 5, timeout: 600, &block)
              logger.info("Starting wait for instance #{id}. Starts in state #{status}.")
              loop do
                refresh
                return [false, "VM #{id} is in a failed state."] if failed?
                break if block.call(self) # rubocop:disable Performance/RedundantBlockCall

                timeout = sleep_counter(sleep_time, timeout)
                return [false, "Time out while waiting #{id} to be stable."] if timeout <= 0
              end
              logger.info("Finished wait for instance #{id}. Ends in state #{status}.")
              [true, 'ok']
            end

            # Wait for the VM instance to be in a stable state. Raise on error.
            # @param sleep_time [Integer] The time to sleep between refreshes.
            # @param timeout [Integer] The number of seconds before raising an error.
            # @param block [Proc] A block to test against. Must return a boolean.
            # @raise [RuntimeError] Instance goes into failed state.
            # @raise [RuntimeError] Timeout has been reached.
            def wait_for!(sleep_time: 5, timeout: 600, &block)
              status, msg = wait_for(:sleep_time => sleep_time, :timeout => timeout, &block)
              return if status

              raise msg
            end
          end
        end
      end
    end
  end
end
