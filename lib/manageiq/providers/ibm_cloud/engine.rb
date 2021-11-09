module ManageIQ
  module Providers
    module IbmCloud
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::IbmCloud

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('IBM Cloud Provider')
        end

        def self.init_loggers
          $ibm_cloud_log ||= Vmdb::Loggers.create_logger("ibm_cloud.log", Vmdb::Loggers::ProviderSdkLogger)
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $ibm_cloud_log, :level_ibm_cloud)
        end
      end
    end
  end
end
