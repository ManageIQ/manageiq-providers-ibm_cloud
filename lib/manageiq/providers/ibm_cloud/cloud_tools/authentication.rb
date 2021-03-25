# frozen_string_literal: true

require 'logger'
require 'ibm_vpc'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Authentication
          class << self
            # Fetch a new Authenticator using IAM token.
            # @param api_key [String]
            # @param logger [Logger, IO, String] Either a Logger object, IO object or path to file.
            #
            # @raise [StandardError] API key is empty.
            # @return [IamAuth]
            def new_iam(api_key, logger: nil)
              raise 'API key is empty.' if api_key.nil?

              IamAuth.new(api_key, :logger => logger)
            end

            # Fetch a new Authenticator using IAM token.
            # @param bearer_info [Hash{Symbol=>String, Integer}] bearer hash with token, expire_time and api_key as keys.
            # @param logger [Logger, IO, String] Either a Logger object, IO object or path to file.
            #
            # @raise [StandardError] Bearer token is empty.
            # @return [BearerAuth]
            def new_bearer(bearer_info, logger: nil)
              raise 'Bearer token info is empty.' if bearer_info.nil?

              BearerAuth.new(bearer_info, :logger => logger)
            end

            # Fetch a new Authenticator using IAM token.
            # @param api_key [String] The IAM OAuth api token.
            # @param bearer_info [Hash{Symbol => String, Integer}] bearer hash with token, expire_time and api_key as keys.
            # @param logger [Logger, IO, String] Either a Logger object, IO object or path to file.
            #
            # @return [BearerAuth]
            def new_auth(api_key: nil, bearer_info: nil, logger: nil)
              raise 'No authentication information given.' if api_key.nil? && bearer_info.nil?

              bearer_info[:api_key] = api_key if !bearer_info.nil? && !api_key.nil?

              return new_bearer(bearer_info, :logger => logger) unless bearer_info.nil?

              iam_auth = new_iam(api_key, :logger => logger)
              new_bearer(iam_auth.bearer_info)
            end
          end

          # API Authentication using Bearer header.
          # @see https://github.com/IBM/ruby-sdk-core/blob/main/lib/ibm_cloud_sdk_core/authenticators/bearer_token_authenticator.rb SDK Bearer doc.
          class BearerAuth < IbmVpc::Authenticators::BearerTokenAuthenticator
            # Convert bearer info into something the superclass understands.
            # @param bearer_info [Hash{Symbol=>String, Integer}] bearer hash with token, expire_time and api_key as keys.
            # @param logger [Logger, IO,String] Either a logger object, a file path or IO object.
            #
            # @return [void]
            def initialize(bearer_info, logger: nil)
              @logger = define_logger(logger)
              @bearer_info = verify_info(bearer_info)
              super({:bearer_token => bearer_info[:token]})
            end

            # @return [Hash{Symbol=>String, Integer}] bearer hash with token, expire_time and api_key as keys.
            attr_reader :bearer_info

            private

            # Verify that the bearer token hasn't expired. If it has and an API Key is present try to get a new bearer token.
            #
            # @return [Hash{Symbol => String, Integer}] @see #bearer_info
            def verify_info(bearer_info)
              # Raise standard error if expiration time expires in the next 10 second.
              if expired?(bearer_info[:expire_time])
                raise 'Bearer token has expired.' if bearer_info[:api_key].nil?

                @logger.info('Bearer token expired. Fetching new one using API Key.')
                return IamAuth.new(bearer_info[:api_key]).bearer_info
              end
              bearer_info
            end

            # Check to see if the token expiry time has elapsed.
            # @param expire_time [Integer, NilClass] The token expiry time provided by IAM.
            #
            # @return [Boolean] True is expired. False is valid.
            def expired?(expire_time)
              return true if expire_time.nil?

              # Checks to see if the expire time will elapse in the next 10 seconds.
              Time.now.to_i >= (expire_time - 10)
            end

            # Define a new logger.
            # @param logger [Logger, IO, String] Either a Logger object, IO object or path to file.
            #
            # @return [Logger]
            def define_logger(logger)
              return logger if logger.kind_of?(Logger)

              Logger.new(logger)
            end
          end

          # IAM authentication using OAUTH API Key.
          # @see https://github.com/IBM/ruby-sdk-core/blob/main/lib/ibm_cloud_sdk_core/authenticators/iam_authenticator.rb SDK IAM doc.
          class IamAuth < IbmVpc::Authenticators::IamAuthenticator
            # Standardize the parameter names throughout the application.
            # @param api_key [String] An IAM API Key.
            # @return [void]
            def initialize(api_key, logger: nil)
              @logger = define_logger(logger)
              super(:apikey => api_key)
            end

            # @return [Hash{Symbol=> String, Integer}] bearer hash with token, expire_time and api_key as keys.
            def bearer_info
              {:token => @token_manager.access_token, :expire_time => @token_manager.token_info["expiration"], :api_key => @apikey}
            end

            private

            # Define a new logger.
            # @param logger [Logger, IO, String] Either a Logger object, IO object or path to file.
            # @return [Logger]
            def define_logger(logger)
              return logger if logger.kind_of?(Logger)

              Logger.new(logger)
            end
          end
        end
      end
    end
  end
end
