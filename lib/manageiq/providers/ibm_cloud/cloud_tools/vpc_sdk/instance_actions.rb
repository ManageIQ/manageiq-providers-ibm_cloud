# frozen_string_literal: true

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module VpcSdk
          class InstanceActions < ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf
            def initialize(vpc:, instance_id:)
              super(:parent => vpc)
              @instance_id = instance_id
            end

            # Send an action request to start the instance.
            def start
              create('start')
            end

            # Send an action request to stop the instance.
            # @param force [Boolean] Clear the queue and run this action.
            def stop(force: false)
              create('stop', :force => force)
            end

            # Send an action request to reboot the instance.
            # @param force [Boolean] Clear the queue and run this action.
            def reboot(force: false)
              create('reboot', :force => force)
            end

            # Send a custom action request.
            # @param action [String] The type of action. Allowable values: [reboot, start, stop]
            # @param force [Boolean] If set to true, the action will be forced immediately, and all queued actions deleted. Ignored for the start action.
            def create(action, force: false)
              logger.info("Sending action request for #{action} with force #{force}.")
              @parent.request(:create_instance_action, :instance_id => @instance_id, :type => action, :force => force)
            end
          end
        end
      end
    end
  end
end
