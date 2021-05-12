# frozen_string_literal: true

require 'json'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Sdk
          # Used to wrap a IBM derived SDK as branch of a CloudTool instance.
          #  @param cloud_tools [CloudTools] An instantiated CloudTools object.
          class Branch
            def initialize(cloudtools:)
              @cloudtools = cloudtools
            end

            attr_reader :cloudtools

            # Interface for logging.
            # @return [Logger]
            def logger
              @cloudtools.logger
            end

            # Get an instantiated instance of the Cloud SDK.
            # @return [Object] The specific Cloud SDK object for the class.
            def client
              client = sdk_client
              client.configure_http_client(:proxy => @cloudtools.proxy.to_hash, :timeout => @cloudtools.timeout.to_hash)
              client
            end

            # Create a generator that removes the need for pagination.
            # @param call_back [String] The method name to use for pagination.
            # @option **kwargs [Any] Accepts random Keyword arguments to be passed unmodified to the callback method.
            #
            # @return [Enumerator] Object to page through results.
            # @yield [Hash] Result of request.
            def collection(call_back, **kwargs)
              raise "Provided call_back #{call_back} does not start with list. This method is for paginating list methods." unless call_back.to_s.match?(/^list/)

              enum_for(:each_resource, call_back, **kwargs)
            end

            # Call a client method and return the hash.
            # @param call_back [String] The SDK method name to get results for.
            # @option **kwargs [Any] Accepts random Keyword arguments to be passed unmodified to the callback method.
            #
            # @return [Hash] The JSON return of the operation with symbolic key names.
            def request(call_back, **kwargs)
              request = send_request(call_back, **kwargs)
              return if request.nil?

              result = request.result
              raise 'Return is not a JSON object' if result.instance_of?(String)

              JSON.parse(JSON.generate(result), :symbolize_names => true)
            end

            private

            # @return [Object] The instantiated client.
            def sdk_client
              raise NotImplementedError, 'Implement sdk_client method in subclass.'
            end

            # Main logic for enumerator is implemented here in subclasses.
            # @param call_back [Symbol] A method on the SDK client.
            # @param kwargs [Any] Should be notated as **kwargs. Captures all keyword args and passes them downstream.
            # @return [Object] The instantiated client.
            def each_resource(_call_back, _kwargs)
              raise NotImplementedError, 'Implement each_resource method in subclass.'
            end

            def send_request(call_back, **kwargs)
              raise "#{client.class.name} does not contain a method #{call_back.to_sym}" unless client.respond_to?(call_back.to_sym)

              return client.send(call_back.to_sym) if kwargs.length.zero?

              client.send(call_back.to_sym, **kwargs)
            end
          end
        end
      end
    end
  end
end
