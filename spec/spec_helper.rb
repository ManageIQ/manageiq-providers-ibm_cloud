if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "manageiq-providers-ibm_cloud"

# Iterate through the SSH keys and replace all values.
# Being very careful with this one as fixing a data leak would be costly.
def replace_ssh_keys(response)
  data = JSON.parse(response.body, :symbolize_names => true)
  return unless data.key?(:keys)

  keys = {:fingerprint => 'SHA256:xxxxxxx', :public_key => 'RSA: VVVVVV'}
  data.fetch(:keys).each_with_index do |v, i|
    v.merge!(keys)
    v[:name] = "random_key_#{i}"
  end
  response.body = data.to_json.force_encoding('ASCII-8BIT')
end

# Replace the contents of the token before writing to file.
def replace_token_contents(response)
  data = JSON.parse(response.body, :symbolize_names => true)
  data.merge!({:refresh_token => 'REFRESH_TOKEN', :ims_user_id => '22222', :expiration => Date.new(2100, 1, 1).to_time.to_i})
  response.body = data.to_json.force_encoding('ASCII-8BIT')
end

# Sanitize VPC VCR files.
def vpc_sanitizier(interaction)
  # Mask bearer token in recorded file.
  interaction.request.headers['Authorization'] = 'Bearer xxxxxx' if interaction.request.headers.key?('Authorization')
  # Replace IP V4 Addresses
  interaction.response.body.gsub!(/([0-9]{1,3}\.){3}/, '127.0.0.')
  # Replace ssh key data.
  replace_ssh_keys(interaction.response)
  interaction
end

VCR.configure do |config|
  # config.debug_logger = $stdout # Keep for debugging tests.
  config.ignore_hosts('codeclimate.com') if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::IbmCloud::Engine.root, 'spec/vcr_cassettes')

  # Used to replace the API Key with the placeholder in the saved VCR.
  config.define_cassette_placeholder('IBM_CLOUD_VPC_API_KEY') { Rails.application.secrets.ibm_cloud_vpc[:api_key] }

  config.before_record do |i|
    replace_token_contents(i.response) if i.request.uri == "https://iam.cloud.ibm.com/identity/token"
    vpc_sanitizier(i) if i.request.uri.match?('iaas.cloud.ibm')
  end

  secrets = Rails.application.secrets
  secrets.ibm_cloud_power.keys do |secret|
    config.define_cassette_placeholder(secrets.ibm_cloud_power_defaults[secret]) { secrets.ibm_cloud_power[secret] }
  end
  secrets.ibm_cloud_vpc.keys do |secret|
    config.define_cassette_placeholder(secrets.ibm_cloud_vpc_defaults[secret]) { secrets.ibm_cloud_vpc[secret] }
  end
end
