# frozen_string_literal: true

require 'forwardable'

require_relative 'instance_actions'

# rubocop:disable Naming/MethodParameterName
module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module VpcSdk
          class Instance < ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf
            TRANSITIONAL_STATES = %w[pausing pending restarting resuming starting stopping].freeze
            ERROR_STATE = 'failed'
            RUNNING_STATE = 'running'
            STOPPED_STATES = %w[stopped paused].freeze

            def initialize(vpc:, id: nil, data: nil)
              super(:parent => vpc)
              @data = define_data(id, data)
            end

            def refresh
              @data = @parent.request(:get_instance, :id => id)
            end

            # The id of this VM.
            def id
              @data[:id]
            end

            # The CRN for the instance.
            def crn
              @data[:crn]
            end

            # The status of the virtual server instance. Possible values: [failed,paused,pausing,pending,restarting,resuming,running,starting,stopped,stopping]
            def status
              @data[:status].downcase
            end

            # Whether the state of the VM is in failed state.
            # @return [Boolean]
            def failed?
              status == ERROR_STATE
            end

            # Whether the state of the VM is in the started state.
            # @return [Boolean]
            def started?
              status == RUNNING_STATE
            end

            # Whether the state of the VM is in a stopped or paused state.
            # @return [Boolean]
            def stopped?
              STOPPED_STATES.include?(status)
            end

            # Whether the state of the VM is in a transitional state.
            # @return [Boolean]
            def transitional?
              TRANSITIONAL_STATES.include?(status)
            end

            def actions
              InstanceActions.new(:vpc => @parent, :instance_id => id)
            end

            def delete
              @parent.request(:delete_instance, :id => id)
            end

            def resize(instance, new_flavor_name)
              @parent.request(:update_instance,
                              :id             => instance[:id],
                              :instance_patch => {
                                :name    => instance[:name],
                                :profile => {:name => new_flavor_name}
                              })
            end

            # Wait for the VM instance to be have a started status.
            # @param sleep_time [Integer] The time to sleep between refreshes.
            # @param timeout [Integer] The number of seconds before raising an error.
            # @raise [RuntimeError] Instance goes into failed state.
            # @raise [RuntimeError] Timeout has been reached.
            def wait_for_started!(sleep_time: 5, timeout: 600)
              wait_for!(:sleep_time => sleep_time, :timeout => timeout, &:started?)
            end

            # Wait for the VM instance to be have a stopped status.
            # @param sleep_time [Integer] The time to sleep between refreshes.
            # @param timeout [Integer] The number of seconds before raising an error.
            # @raise [RuntimeError] Instance goes into failed state.
            # @raise [RuntimeError] Timeout has been reached.
            def wait_for_stopped!(sleep_time: 5, timeout: 600)
              wait_for!(:sleep_time => sleep_time, :timeout => timeout, &:stopped?)
            end

            private

            # Sleep for the specificed time and decrement timout by that number.
            # @return [Integer] The current timeout.
            def sleep_counter(sleep_time, timeout)
              sleep sleep_time
              timeout - sleep_time
            end

            # Return a hash with the instnace data.
            def define_data(instid, data)
              return data unless data.nil?
              return @parent.request(:get_instance, :id => instid) unless instid.nil?

              raise 'Unable to set instance data.'
            end

            extend Forwardable
            def_delegators :@data, :[], :dig, :each, :each_pair, :fetch, :has_key?, :has_value?, :include?, :index, :inspect, :key?, :keys, :length, :merge, :merge!, :clear, :to_h, :value?, :values, :pretty_print, :get
          end
        end
      end
    end
  end
end
# rubocop:enable Naming/MethodParameterName
