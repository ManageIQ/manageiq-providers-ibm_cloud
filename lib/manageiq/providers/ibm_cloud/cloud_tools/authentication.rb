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
              raise 'Bearer info must be a hash.' unless bearer_info.kind_of?(Hash)
              raise 'Bearer info must have a key named :token.' unless bearer_info.key?(:token)

              @logger = define_logger(logger)
              @bearer_info = bearer_info
              super({:bearer_token => bearer_info[:token]})
            end

            # @return [Hash{Symbol=>String, Integer}] bearer hash with token, expire_time and api_key as keys.
            attr_reader :bearer_info

            def authenticate(headers)
              verify_bearer
              super(headers)
            end

            private

            # Check to see if bearer token has expired. If it has fetch a new one.
            # @return [void]
            def verify_bearer
              if expired?(@bearer_info[:expire_time])
                @bearer_info = new_bearer(@bearer_info)
                @bearer_token = @bearer_info[:token]
              end
            end

            # Get a new bearer token.
            # @param bearer_info [Hash{Symbol=>String, Integer}] Bearer info hash from IamAuth
            # @return [Hash{Symbol=>String, Integer}] Bearer info hash from IamAuth
            def new_bearer(bearer_info)
              raise 'Bearer token has expired and unable to refresh. An api key is not present in bearer_info hash.' if bearer_info[:api_key].nil?

              @logger.info('Bearer token expired. Fetching new one using API Key.')
              IamAuth.new(bearer_info[:api_key]).bearer_info
            end

            # Check to see if the token expire_time has elapsed.
            # @param expire_time [Integer, NilClass] The token expire_time provided by IAM.
            #
            # * An expire_time with a nil value will disable the validation check. The token will be used as-is for the request.
            # * An expire_time that cannot be used as an integer will force a refresh of the token from IAM.
            #
            # @return [Boolean] True is expired. False is valid.
            def expired?(expire_time)
              return false if expire_time.nil? # Assume that expire check is disabled.
              return true unless expire_time.respond_to?(:to_i) # Verify that expire_time can be converted into an integer.

              # Checks to see if the expire time will elapse in the next 10 seconds.
              # True if now is greater than expire time. False if now is less than expire time.
              Time.now.to_i >= (expire_time.to_i - 10)
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
              {:token => token, :expire_time => expire_time, :api_key => @apikey}
            end

            private

            # Validate that the bearer token was successfully retrieved and populated.
            # @return [String]
            def token
              access_token = @token_manager.access_token
              raise 'CloudTools::IAMAuth Unable to retrieve the access token from token manager.' if access_token.nil?

              access_token
            end

            # Validate that the bearer token expiry time can be retrieved and is an Integer.
            # @return [Integer]
            def expire_time
              e_time = @token_manager.token_info["expiration"]
              raise 'CloudTools::IAMAuth Unable to extract the retrieved expiration time.' if e_time.nil?
              raise "CloudTools::IAMAuth Extracted expiry time #{e_time} is not an expected integer." unless e_time.kind_of?(Integer)

              e_time
            end

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
