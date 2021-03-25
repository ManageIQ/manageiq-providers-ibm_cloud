# frozen_string_literal: true

# rubocop:disable Style/MethodCallWithArgsParentheses # Guidance does not conform to preferred expect formatting.
describe ManageIQ::Providers::IbmCloud::CloudTools::Authentication do
  let(:api_key) { Rails.application.secrets.ibmcvs.try(:[], :api_key) || 'IBMCVS_API_KEY' }

  # @param has_expired_time [Boolean] Include expire_time in returned hash.
  # @param backdate_expired_time [Boolean] Set the expire_time to sometime in the past.
  # @param has_api_key [Boolean] Include
  # @return [Hash{Symbol => String, Integer}] Set
  def create_bearer_info(valid_expire_time: true, set_api_key: true)
    info = {:token => 'eyJraWQiOiIyMDIxMDIxOTE4MzUiLCJhbGciOiJSUzI1NiJ9'}

    case valid_expire_time
    when true
      info[:expire_time] = Date.new(2100, 1, 1).to_time.to_i # Set the date to 2100, so it is always valid.
    when false
      info[:expire_time] = 1_615_813_308
    end

    case set_api_key
    when true
      info[:api_key] = api_key
    when false
      info[:api_key] = nil
    end

    info
  end

  it 'Can directly get a new auth using api_key only.' do
    VCR.use_cassette(described_class.name.underscore) do
      auth = described_class.new_iam(api_key)
      expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::IamAuth)
    end
  end

  context described_class::IamAuth do
    it 'It returns an instance that has and ancestor of IBMCloudSdkCore::IamAuthenticator' do
      VCR.use_cassette(described_class.name.underscore) do
        expect(described_class.new(api_key)).to be_a(IBMCloudSdkCore::IamAuthenticator)
      end
    end

    it 'IamAuth has a valid bearer_info' do
      VCR.use_cassette(described_class.name.underscore) do
        auth = described_class.new(api_key)

        expect(auth).to be_a(described_class)

        bearer_info = auth.bearer_info
        expect(bearer_info).to be_a(Hash)

        expect(bearer_info).to include(:api_key)
        expect(bearer_info[:api_key]).to_not be_nil
        expect(bearer_info[:api_key]).to be_a(String)

        expect(bearer_info).to include(:token)
        expect(bearer_info[:token]).to_not be_nil
        expect(bearer_info[:token]).to be_a(String)

        expect(bearer_info).to include(:expire_time)
        expect(bearer_info[:expire_time]).to_not be_nil
        expect(bearer_info[:expire_time]).to be_a(Integer)
      end
    end
  end

  it 'Can directly get a new auth using bearer_info only.' do
    auth = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_bearer(create_bearer_info)
    expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
  end

  context described_class::BearerAuth do
    it 'It returns an instance that has and ancestor of IBMCloudSdkCore::BearerTokenAuthenticator' do
      expect(described_class.new(create_bearer_info)).to be_a(IBMCloudSdkCore::BearerTokenAuthenticator)
    end

    it 'BearerAuth has valid bearer_info keys' do
      auth = described_class.new(create_bearer_info)
      expect(auth).to be_a(described_class)

      bearer_info = auth.bearer_info
      expect(bearer_info).to be_a(Hash)

      expect(bearer_info).to include(:api_key)
      expect(bearer_info[:api_key]).to_not be_nil
      expect(bearer_info[:api_key]).to be_a(String)

      expect(bearer_info).to include(:token)
      expect(bearer_info[:token]).to_not be_nil
      expect(bearer_info[:token]).to be_a(String)

      expect(bearer_info).to include(:expire_time)
      expect(bearer_info[:expire_time]).to_not be_nil
      expect(bearer_info[:expire_time]).to be_a(Integer)
    end
  end

  context 'Testing new_auth parameters mixtures' do
    it 'Can get generic new_auth using api key only' do |example|
      VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
        auth = described_class.new_auth(:api_key => api_key)
        expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
      end
    end

    it 'Can get generic new_auth using bearer info only' do |example|
      VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
        auth = described_class.new_auth(:bearer_info => create_bearer_info)
        expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
      end
    end

    it 'Cannot get generic new_auth using expired bearer info and no api key.' do |example|
      VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
        bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => false)
        expect { ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:bearer_info => bearer_info) }.to raise_error(StandardError)
      end
    end

    it 'Can get generic new_auth using expired bearer info and api key.' do |example|
      VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
        bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => true)
        auth = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:bearer_info => bearer_info)
        expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
      end
    end

    it 'Can get generic new_auth using expired bearer info and provided api key.' do |example|
      VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
        bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => false)
        auth = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:api_key => api_key, :bearer_info => bearer_info)
        expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
      end
    end
  end
end

describe ManageIQ::Providers::IbmCloud::CloudTool do
  let(:api_key) { Rails.application.secrets.ibmcvs.try(:[], :api_key) || 'IBMCVS_API_KEY' }

  it 'raises error on with not options given' do |example|
    VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
      expect { described_class.new }.to raise_exception(RuntimeError)
    end
  end

  it 'can get a VPC client' do |example|
    VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
      expect(described_class.new(:api_key => api_key).vpc(:region => 'us-east').client).to be_a(IbmVpc::VpcV1)
    end
  end

  it 'can get a Tagging client' do |example|
    VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
      expect(described_class.new(:api_key => api_key).tagging.client).to be_a(IbmCloudGlobalTagging::GlobalTaggingV1)
    end
  end

  it 'VPC can get a response' do |example|
    VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
      vpc = described_class.new(:api_key => api_key).vpc(:region => 'us-east')
      response = vpc.request('list_images', :limit => 1)
      expect(response).to be_a(Hash)
      expect(response).to include(:images)
      expect(response[:images]).to be_a(Array)
      expect(response[:images].length).to eq(1)
    end
  end

  it 'VPC can paginate' do |example|
    VCR.use_cassette("#{described_class.name.underscore}/#{example.description}") do
      vpc = described_class.new(:api_key => api_key).vpc(:region => 'us-east')
      response = vpc.collection('list_images', :limit => 1)
      expect(response).to be_a(Enumerator)
      expect(response.next).to be_a(Hash)
      expect(response.next).to be_a(Hash)
    end
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses
