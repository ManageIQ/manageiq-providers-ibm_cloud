# frozen_string_literal: true

require 'logging'
require_relative 'cloud_tools'

module ManageIQ
  module Providers
    module IbmCloud
      # Collects and simplifies the intialization of IBM Cloud SDKs.
      # @param apk_key [String] A valid IAM API Key.
      class CloudTool
        def initialize(api_key: nil, bearer_token: nil, logger: nil)
          @api_key = api_key
          @logger = define_logger(logger)
          @bearer_token = bearer_token
        end

        attr_reader :logger

        # A proxy object used for setting proxy configurations.
        # @return [Proxy]
        def proxy
          @proxy ||= CloudTools::Common::Proxy.new
        end

        # A timeout object used for setting HTTP timeout configurations.
        # @return [Timeout]
        def timeout
          @timeout ||= CloudTools::Common::Timeout.new
        end

        # A IBM CLoud SDK authentication object.
        # @return [IamAuthenticator]
        def authenticator
          @authenticator ||= CloudTools::Authentication.new_auth(:api_key => @api_key, :bearer_token => @bearer_token)
        end

        # Access the tagging cloud interface.
        # @return [Tagging]
        def tagging
          @tagging ||= CloudTools::GlobalTag.new(:cloudtools => self)
        end

        # Access the IBM Cloud VPC interface.
        # @return [Vpc]
        def vpc(region: 'us-east', version: '2021-01-01', generation: 2)
          @vpc ||= CloudTools::Vpc.new(:cloudtools => self, :region => region, :version => version, :generation => generation)
        end

        private

        # Set a new logger
        # @param logger [Logger | String] Either an object that responds to info or string.
        # @return [Logger] An instance of a Logger.
        def define_logger(logger)
          return logger if logger.respond_to?(:info)

          Logger.new(logger)
        end
      end
    end
  end
end
