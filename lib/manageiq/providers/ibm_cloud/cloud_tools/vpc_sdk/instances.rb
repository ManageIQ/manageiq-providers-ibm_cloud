# frozen_string_literal: true

require_relative 'instance'

# rubocop:disable Naming/MethodParameterName
module ManageIQ
  module Providers
    module IbmCloud
      module CloudTools
        module VpcSdk
          class Instances < ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf
            def all(**kwargs)
              @parent.collection(:list_instances, **kwargs)
            end

            def instance(id)
              Instance.new(:vpc => @parent, :id => id)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Naming/MethodParameterName
