# frozen_string_literal: true

require 'logging'
require_relative 'cloud_tools'

module ManageIQ
  module Providers
    module IbmCloud
      # Collects and simplifies the initialization of IBM Cloud SDKs.
      class CloudTool
        # Initialize the class variables for the key but do not use them until a SDK method is called.
        # @param api_key [String] A valid IAM API Key or Access Token.
        # @param bearer_token [String] The type of key that is given.
        # @param logger [NilClass, String, {Logger}] Instantiate logger with no output. Filesystem path to print logs to. An instance of a object that implements Logger.
        # @return [void]
        def initialize(api_key: nil, bearer_token: nil, logger: nil)
          @api_key = api_key
          @logger = define_logger(logger)
          @bearer_token = bearer_token
        end

        # @return [Logger] a Ruby Logger instance.
        attr_reader :logger

        # @return [CloudTools::Common::Proxy] a proxy object used for setting proxy configurations.
        def proxy
          @proxy ||= CloudTools::Common::Proxy.new
        end

        # @return [CloudTools::Common::Timeout] a timeout object used for setting HTTP timeout configurations.
        def timeout
          @timeout ||= CloudTools::Common::Timeout.new
        end

        # An IBM CLoud SDK authentication object.
        # @param use_bearer [Boolean]
        # @return [CloudTools::Common::IamAuth]
        def authenticator
          @authenticator ||= CloudTools::Authentication.new_auth(:api_key => @api_key, :bearer_token => @bearer_token)
        end

        # @return [CloudTools::GlobalTag] the CloudTools GlobalTagging SDK wrapper.
        def tagging
          @tagging ||= CloudTools::GlobalTag.new(:cloudtools => self)
        end

        # Access the IBM Cloud VPC interface.
        # @param region [String] The region to query with the VPC SDK.
        # @param version [String] A maximum date that the VPC API should return.
        # @param generation [Integer] The generation of VPC to use.
        # @return [CloudTools::Vpc] the CloudTools VPC SDK wrapper.
        def vpc(region: 'us-east', version: '2021-01-01', generation: 2)
          @vpc ||= CloudTools::Vpc.new(:cloudtools => self, :region => region, :version => version, :generation => generation)
        end

        private

        # Set a new logger
        # @param logger [Logger, String, NilClass]An object that implement the Ruby Logger interface. A filesystem path where the log file should send its contents. A null logger.
        # @return [Logger] An instance of a Logger.
        def define_logger(logger)
          return logger if logger.respond_to?(:info)

          Logger.new(logger)
        end
      end
    end
  end
end
