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
      ## TODO: Delete resources
    end
  end
end
