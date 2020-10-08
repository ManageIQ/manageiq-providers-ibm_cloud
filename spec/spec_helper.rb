if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq-providers-ibm_cloud"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::IbmCloud::Engine.root, 'spec/vcr_cassettes')
  config.before_record do |i|
    # The ibm-cloud-sdk gem attempts to auto-renew the Bearer token if it
    # detects that it is expired.  This causes unhandled http interactions
    # after the expiration time.  We can replace the expiration time with
    # one way in the future to prevent this.
    if i.request.uri == "https://iam.cloud.ibm.com/identity/token"
      body = JSON.parse(i.response.body)
      body["expiration"] = Date.new(2100, 1, 1).to_time.to_i
      i.response.body = body.to_json
    end
  end
end
