namespace :vcr do
  namespace :power_virtual_servers do
    require "ibm_cloud_iam"
    require "ibm_cloud_resource_controller"
    require 'ibm_cloud_power'

    base_dir = ManageIQ::Providers::IbmCloud::Engine.root.join("spec")
    cass_dir = base_dir.join("vcr_cassettes/manageiq/providers/ibm_cloud")
    spec_dir = base_dir.join("models/manageiq/providers/ibm_cloud")

    desc "Full re-record of PowerVS refresher VCR, including PowerVS resource setup and cleanup"
    task :rerecord => :environment do
      Rake::Task['vcr:power_virtual_servers:setup'].invoke
      Rake::Task['vcr:power_virtual_servers:record'].invoke
      Rake::Task['vcr:power_virtual_servers:cleanup'].invoke
    end

    desc "Setup PowerVS resources required for refresher spec"
    task :setup => :environment do
      # Setup connection to PowerVS service
      connection, cloud_instance_id = connect

      ## TODO: Create resources
    end

    desc "Record new PowerVS refresh spec VCR cassette"
    task :record => :environment do
      # Run refresher spec
      # Delete existing VCR cassette
      cass_dir.glob("power_virtual_servers/cloud_manager/**/*.yml").each(&:delete)
      spec_file = spec_dir.join("power_virtual_servers/cloud_manager/refresher_spec.rb")
      `bundle exec rspec #{spec_file}`
    end

    desc "Clean up PowerVS resources required for refresher spec"
    task :cleanup => :environment do
      # Setup connection to PowerVS service
      connection, cloud_instance_id = connect

      ## TODO: Delete resources
    end

    def connect
      # Prerequisites:
      # 1. Place IBM Cloud API key in secrets config
      # 2. Place PowerVS 'cloud_instance_id' (service guid) in secrets config

      # Setup IBM Cloud PowerVS connection
      begin
        api_key = YAML.load_file("config/secrets.yml").dig("test", "ibm_cloud_power", "api_key")
      rescue NoMethodError
        raise "IBM Cloud API key not found in secrets config file"
      end

      begin
        cloud_instance_id = YAML.load_file("config/secrets.yml").dig("test", "ibm_cloud_power", "cloud_instance_id")
      rescue NoMethodError
        raise "PowerVS 'cloud_instance_id' not found in secrets config file"
      end

      iam_token_api           = IbmCloudIam::TokenOperationsApi.new
      token                   = iam_token_api.get_token_api_key("urn:ibm:params:oauth:grant-type:apikey", api_key)
      authenticator           = IbmCloudResourceController::Authenticators::BearerTokenAuthenticator.new(:bearer_token => token.access_token)
      resource_controller_api = IbmCloudResourceController::ResourceControllerV2.new(:authenticator => authenticator)
      power_iaas_service      = resource_controller_api.get_resource_instance(:id => cloud_instance_id).result

      _crn, _version, _cname, _ctype, _service_name, location, scope, _service_instance, _resource_type, _resource = power_iaas_service["crn"].split(":")
      region    = location.sub(/-*\d+$/, '')
      host      = ManageIQ::Providers::IbmCloud::PowerVirtualServers::Regions.regions[region][:hostname]
      tenant_id = scope.split('/')[1]

      connection                                  = IbmCloudPower::ApiClient.new
      connection.config.api_key                   = api_key
      connection.config.scheme                    = "https"
      connection.config.host                      = host
      connection.config.logger                    = $ibm_cloud_log
      connection.config.debugging                 = Settings.log.level_ibm_cloud == "debug"
      connection.default_headers["Crn"]           = power_iaas_service["crn"]
      connection.default_headers["Authorization"] = "#{token.token_type} #{token.access_token}"

      return connection, tenant_id, cloud_instance_id
    end
  end
end
