module ManageIQ
  module Providers
    module IbmCloud
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::IbmCloud

        config.autoload_paths << root.join('lib').to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('ManageIQ Providers Ibm Cloud')
        end
      end
    end
  end
end
