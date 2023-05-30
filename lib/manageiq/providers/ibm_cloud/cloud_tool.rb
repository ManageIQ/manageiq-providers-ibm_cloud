# frozen_string_literal: true

require 'logger'
require_relative 'cloud_tools'

module ManageIQ
  module Providers
    module IbmCloud
      # Collects and simplifies the initialization of IBM Cloud SDKs.
      class CloudTool
        # Initialize the class variables for the key but do not use them until a SDK method is called.
        # @param api_key [String] A valid IAM API Key or Access Token.
        # @param bearer_info [Hash{Symbol => String, Integer}] Hash retrieved from #authenticator#bearer_info
        # @param logger [Logger, IO, String] A logger instance, IO instance or path to a file.
        #
        # @return [void]
        def initialize(api_key: nil, bearer_info: nil, logger: nil)
          raise 'Required api_key or bearer_info not provided' if api_key.nil? && bearer_info.nil?

          @api_key = api_key
          @bearer_info = bearer_info
          @logger = define_logger(logger)
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
        # @return [ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth]
        def authenticator
          @authenticator ||= CloudTools::Authentication.new_auth(:api_key => @api_key, :bearer_info => @bearer_info)
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

        def events(service_key:, region: 'us-east')
          @events ||= CloudTools::ActivityTracker.new(:cloudtools => self, :region => region, :service_key => service_key)
        end

        def databases(region: 'us-east')
          @databases ||= CloudTools::CloudDatabases.new(:cloudtools => self, :region => region)
        end

        # Get a class that accesses the IBM Cloud Resource Manager API.
        # @return [CloudTools::ResourceController] the CloudTools Resource Manager SDK wrapper.
        def resource
          @resource ||= CloudTools::ResourceController.new(:cloudtools => self)
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
