require 'kubeclient'
require 'recursive-open-struct'
require 'ibm_cloud_iam'

require_relative '../../../workers/container_event_catcher/event_catcher'

RSpec.describe EventCatcher do
  let(:ems)            { {'id' => 1, 'uid_ems' => 'my-iks-cluster', 'type' => 'ManageIQ::Providers::IbmCloud::ContainerManager', 'ems_type' => 'iks'} }
  let(:endpoint)       { {'hostname' => 'iks.example.com', 'port' => 443, 'security_protocol' => 'ssl-with-validation'} }
  let(:authentication) { {'authtype' => 'bearer', 'auth_key' => 'my-iam-api-key'} }
  let(:settings)       { {'ems' => {'ems_iks' => {'blacklisted_event_names' => []}}} }
  let(:logger)         { instance_double('Logger', :info => nil, :warn => nil) }
  let(:catcher)        { described_class.new(ems, endpoint, authentication, settings, {}, logger) }

  describe '#log_prefix' do
    it 'returns the IBM Cloud ContainerManager class name' do
      expect(catcher.send(:log_prefix)).to eq('MIQ(ManageIQ::Providers::IbmCloud::ContainerManager::EventCatcher)')
    end
  end

  describe '#auth_options' do
    let(:fake_id_token)  { 'eyJ.fake-iks-id-token' }
    let(:fake_expiry)    { (Time.now.utc + 3600).to_i }
    let(:fake_response) do
      instance_double('IbmCloudIam::TokenResponse',
                      :id_token   => fake_id_token,
                      :expiration => fake_expiry)
    end
    let(:fake_api) { instance_double('IbmCloudIam::TokenOperationsApi') }

    before do
      allow(IbmCloudIam::TokenOperationsApi).to receive(:new).and_return(fake_api)
      allow(fake_api).to receive(:get_token_api_key).and_return(fake_response)
    end

    it 'calls get_token_api_key with the correct grant_type, header_params, and auth_key' do
      expect(fake_api).to receive(:get_token_api_key) do |grant_type, api_key, opts|
        expect(grant_type).to eq('urn:ibm:params:oauth:grant-type:apikey')
        expect(api_key).to eq('my-iam-api-key')
        expect(opts[:header_params]['Content-Type']).to eq('application/x-www-form-urlencoded')
        expect(opts[:header_params]['Authorization']).to eq('Basic a3ViZTprdWJl')
        expect(opts[:header_params]['cache-control']).to eq('no-cache')
        fake_response
      end

      catcher.send(:auth_options)
    end

    it 'returns a bearer_token hash using id_token' do
      expect(catcher.send(:auth_options)).to eq(:bearer_token => fake_id_token)
    end

    it 'sets @token_expiry to a UTC Time from the expiration unix timestamp' do
      catcher.send(:auth_options)
      expect(catcher.send(:token_expiry)).to eq(Time.at(fake_expiry).utc)
    end

    context 'when expiration is nil' do
      let(:fake_response) do
        instance_double('IbmCloudIam::TokenResponse',
                        :id_token   => fake_id_token,
                        :expiration => nil)
      end

      it 'sets @token_expiry to nil' do
        catcher.send(:auth_options)
        expect(catcher.send(:token_expiry)).to be_nil
      end
    end
  end

  describe '#token_expiry' do
    it 'returns nil before auth_options is called' do
      expect(catcher.send(:token_expiry)).to be_nil
    end
  end

  describe '#build_client' do
    let(:fake_id_token)  { 'eyJ.fresh-iks-token' }
    let(:fake_expiry)    { (Time.now.utc + 3600).to_i }
    let(:fake_response) do
      instance_double('IbmCloudIam::TokenResponse',
                      :id_token   => fake_id_token,
                      :expiration => fake_expiry)
    end
    let(:fake_api)    { instance_double('IbmCloudIam::TokenOperationsApi') }
    let(:fake_client) { instance_double('Kubeclient::Client', :discover => nil) }

    before do
      allow(IbmCloudIam::TokenOperationsApi).to receive(:new).and_return(fake_api)
      allow(fake_api).to receive(:get_token_api_key).and_return(fake_response)
    end

    it 'passes auth_options result to Kubeclient::Client' do
      expect(Kubeclient::Client).to receive(:new) do |_uri, _version, opts|
        expect(opts[:auth_options]).to eq(:bearer_token => fake_id_token)
        fake_client
      end

      catcher.send(:build_client)
    end

    it 'fetches a fresh token on every build_client call' do
      allow(Kubeclient::Client).to receive(:new).and_return(fake_client)
      expect(fake_api).to receive(:get_token_api_key).twice.and_return(fake_response)

      catcher.send(:build_client)
      catcher.send(:build_client)
    end
  end
end
