# frozen_string_literal: true

require 'ibm_vpc'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Authentication
          class << self
            # Set that params for the auth
            # @param api_key [String] The API Key string.
            # @param bearer_token [String] The Bearer Token string.
            # @return [Hash<Symbol, String>]
            def vars(api_key: nil, bearer_token: nil)
              setup = {}
              setup[:apikey] = api_key unless api_key.nil?
              setup[:bearer_token] = bearer_token unless bearer_token.nil?
              setup
            end

            # Fetch a new Authenticator using IAM token.
            # @param api_key [String]
            # @raise [StandardError] API key is empty.
            # @return [IamAuth]
            def new_iam(api_key)
              raise 'API key is empty.' if api_key.nil?

              IamAuth.new(vars(:api_key => api_key))
            end

            # Fetch a new Authenticator using IAM token.
            # @param bearer_token [String]
            # @raise [StandardError] Bearer token is empty.
            # @return [IbmVpc::Authenticators::BearerTokenAuthenticator]
            def new_bearer(bearer_token)
              raise 'Bearer token is empty.' if bearer_token.nil?

              BearerAuth.new(vars(:bearer_token => bearer_token))
            end

            # Fetch a new Authenticator using IAM token.
            # @param api_key [String]
            # @param bearer_token [String]
            # @return [IbmVpc::Authenticators::BearerTokenAuthenticator]
            def new_auth(api_key:, bearer_token: nil)
              return new_bearer(bearer_token) unless bearer_token.nil?

              iam_auth = new_iam(api_key)
              new_bearer(iam_auth.bearer_token)
            end
          end

          class BearerAuth < IbmVpc::Authenticators::BearerTokenAuthenticator
            # @return [String] The configured bearer_token.
            attr_reader :bearer_token
          end

          # A class to allow for auth manipulation.
          class IamAuth < IbmVpc::Authenticators::IamAuthenticator
            # @return [String] The retrieved access token.
            def bearer_token
              @token_manager.access_token
            end
          end
        end
      end
    end
  end
end
