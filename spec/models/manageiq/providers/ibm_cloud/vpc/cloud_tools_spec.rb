# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::CloudTools do
  let(:vcr_location) { 'manageiq/providers/ibm_cloud/cloudtools' }
  let(:api_key) { Rails.application.secrets.ibmcvs.try(:[], :api_key) || 'IBMCVS_API_KEY' }
  let(:vpc) { ManageIQ::Providers::IbmCloud::CloudTool.new(:api_key => api_key).vpc(:region => 'us-east') }

  it 'raises error on empty apikey' do
    expect { ManageIQ::Providers::IbmCloud::CloudTool.new(:api_key => nil) }.to raise_exception(RuntimeError)
  end

  describe ManageIQ::Providers::IbmCloud::CloudTools::Vpc do
    it 'can be instantiated' do
      vpc
    end

    it 'can get a client' do
      VCR.use_cassette("#{vcr_location}/vpc_token") { expect(vpc.client).to be_kind_of(IbmVpc::VpcV1) }
    end

    it 'can get a response' do
      VCR.use_cassette("#{vcr_location}/vpc_response") { vpc.request('list_volumes') }
    end

    it 'can enumerate' do
      VCR.use_cassette("#{vcr_location}/vpc_collection") { vpc.collection('list_volumes').to_a }
    end
  end
end
