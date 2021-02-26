# frozen_string_literal: true

# Create a module that can be used as a mixin for either Vms or Templates.
# The ActiveSupport Concern allows for it to be shared amongst classses.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::VmOrTemplateShared
  extend ActiveSupport::Concern
end
