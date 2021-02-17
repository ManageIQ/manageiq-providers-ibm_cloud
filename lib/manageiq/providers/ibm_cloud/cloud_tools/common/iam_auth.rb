# frozen_string_literal: true

require 'ibm_vpc'

module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module Common
          # A class to allow for auth manipulation.
          class IamAuth < IbmVpc::Authenticators::IamAuthenticator
            attr_accessor :token_manager
          end
        end
      end
    end
  end
end
