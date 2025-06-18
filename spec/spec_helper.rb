if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "manageiq/providers/ibm_cloud"

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
def replace_token_contents(interaction)
  data = JSON.parse(interaction.response.body, :symbolize_names => true)
  data.merge!({:access_token => 'ACCESS_TOKEN', :refresh_token => 'REFRESH_TOKEN', :ims_user_id => '22222', :expiration => Date.new(2100, 1, 1).to_time.to_i})
  interaction.response.body = data.to_json.force_encoding('ASCII-8BIT')

  transient_headers = %w[].freeze
  header_sanitizer(interaction.response.headers, transient_headers)
end

# Sanitize VPC VCR files.
def vpc_sanitizer(interaction)
  # Mask bearer token in recorded file.
  interaction.request.headers['Authorization'] = 'Bearer xxxxxx' if interaction.request.headers.key?('Authorization')

  # Replace headers so that they don't get updated each regeneration.
  transient_headers = %w[__cfduid Cf-Ray Cf-Request-Id X-Request-Id X-Trace-Id].freeze
  header_sanitizer(interaction.response.headers, transient_headers)

  # Replace IP V4 Addresses
  interaction.response.body.gsub!(/([0-9]{1,3}\.){3}/, '127.0.0.')
  # Replace ssh key data.
  replace_ssh_keys(interaction.response)
  interaction
end

# Remove headers that are transient and unused.
def header_sanitizer(response_header, transient_headers)
  default_headers = %w[Date Set-Cookie X-Envoy-Upstream-Service-Time Transaction-Id Server]
  all_headers = default_headers + transient_headers

  all_headers.each do |header|
    response_header.delete(header) if response_header.key?(header)
  end
end

VCR.configure do |config|
  config.ignore_hosts('codeclimate.com') if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::IbmCloud::Engine.root, 'spec/vcr_cassettes')
  config.hook_into(:webmock)
  config.configure_rspec_metadata! # Auto-detects the cassette name based on the example's full description

  config.before_record do |i|
    replace_token_contents(i) if i.request.uri == "https://iam.cloud.ibm.com/identity/token"
    vpc_sanitizer(i) if i.request.uri.match?('iaas.cloud.ibm') || i.request.uri.match?('tags.global-search-tagging')
  end

  VcrSecrets.define_all_cassette_placeholders(config, :ibm_cloud_power)
  VcrSecrets.define_all_cassette_placeholders(config, :ibm_cloud_vpc)
  VcrSecrets.define_all_cassette_placeholders(config, :ibm_cloud_object_storage)
  VcrSecrets.define_all_cassette_placeholders(config, :iks)
end
