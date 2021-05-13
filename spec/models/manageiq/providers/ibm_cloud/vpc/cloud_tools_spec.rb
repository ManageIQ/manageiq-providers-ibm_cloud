# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::CloudTools::Authentication, :vcr do
  let(:api_key) { Rails.application.secrets.ibm_cloud_vpc[:api_key] }

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
    auth = described_class.new_iam(api_key)
    expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::IamAuth)
  end

  context described_class::IamAuth do
    it 'It returns an instance that has and ancestor of IBMCloudSdkCore::IamAuthenticator' do
      expect(described_class.new(api_key)).to be_a(IBMCloudSdkCore::IamAuthenticator)
    end

    it 'IamAuth has a valid bearer_info' do
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
    it 'Can get generic new_auth using api key only' do
      auth = described_class.new_auth(:api_key => api_key)
      expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
    end

    # New bearer class returned with only bearer info given.
    it 'Can get generic new_auth using bearer info only' do
      auth = described_class.new_auth(:bearer_info => create_bearer_info)
      expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
    end

    # An error should raise if there is no api key set.
    it 'Cannot get generic new_auth using expired bearer info and no api key.' do
      bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => false)
      expect(bearer_info[:expire_time]).to be < Time.now.to_i

      authentication = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:bearer_info => bearer_info)
      expect { authentication.authenticate }.to raise_error(StandardError)
    end

    # In this test we use a api key set in bearer info hash with no api key set in the constructor.
    it 'Can get generic new_auth using expired bearer info and api key.' do
      bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => true)
      old_expire = bearer_info[:expire_time]

      auth = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:bearer_info => bearer_info)
      expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)
      # Check expiry and update if necessary.
      auth.authenticate({})
      expect(auth.bearer_info[:expire_time]).not_to eq(old_expire)
    end

    # In this test we use a bearer info hash with no api key and a api key set in the constructor.
    it 'Can get generic new_auth using expired bearer info and provided api key.' do
      bearer_info = create_bearer_info(:valid_expire_time => false, :set_api_key => false)
      old_expire = bearer_info[:expire_time]

      expect(bearer_info[:api_key]).to be_nil
      auth = ManageIQ::Providers::IbmCloud::CloudTools::Authentication.new_auth(:api_key => api_key, :bearer_info => bearer_info)
      expect(auth).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Authentication::BearerAuth)

      # Check expiry and update if necessary.
      auth.authenticate({})
      expect(auth.bearer_info[:expire_time]).not_to eq(old_expire)
    end
  end
end

describe ManageIQ::Providers::IbmCloud::CloudTool, :vcr do
  let(:api_key) { Rails.application.secrets.ibm_cloud_vpc[:api_key] }
  let(:region) { 'us-east' }
  let(:vpc) { ManageIQ::Providers::IbmCloud::CloudTool.new(:api_key => api_key).vpc(:region => region) }

  it 'raises error on with not options given' do
    expect { described_class.new }.to raise_exception(RuntimeError)
  end

  # Test that the VPC client can be instantiated.
  it 'can get a VPC client' do
    expect(described_class.new(:api_key => api_key).vpc(:region => region).client).to be_a(IbmVpc::VpcV1)
  end

  # Test that a initialized VPC class can refresh its token if expired.
  it 'can get a VPC client with expired auth' do
    cloud_tool = described_class.new(:api_key => api_key)
    expect(cloud_tool.vpc(:region => region).client).to be_a(IbmVpc::VpcV1)
    orig_expiry = cloud_tool.vpc.client.authenticator.bearer_info[:expire_time]

    # Set expire time to something really old.
    cloud_tool.vpc.client.authenticator.bearer_info[:expire_time] = 1111
    expect(cloud_tool.vpc.client.authenticator.bearer_info[:expire_time]).to eq(1111)

    # On request the expiry should be checked and a new token retrieved.
    expect(cloud_tool.vpc.request(:list_subnets)).to be_a(Hash)

    # The new expire time should not be the same as the one manually set.
    expect(cloud_tool.vpc.client.authenticator.bearer_info[:expire_time]).to_not eq(1111)

    # VCR will reset the token information.
    expect(cloud_tool.vpc.client.authenticator.bearer_info[:expire_time]).to eq(orig_expiry)
  end

  # Test that the tagging client can get tags.
  it 'can get a Tagging client' do
    cloud_tool = described_class.new(:api_key => api_key)
    expect(cloud_tool.tagging.client).to be_a(IbmCloudGlobalTagging::GlobalTaggingV1)
    tags = cloud_tool.tagging.request(:list_tags, :limit => 1)
    expect(tags).to be_a(Hash)
    expect(tags[:items]).to be_a(Array)
    expect(tags[:items].length).to eq(1)
  end

  it 'VPC can get a response' do
    response = vpc.request('list_images', :limit => 1)
    expect(response).to be_a(Hash)
    expect(response).to include(:images)
    expect(response[:images]).to be_a(Array)
    expect(response[:images].length).to eq(1)
  end

  it 'VPC can paginate' do
    response = vpc.collection('list_images', :limit => 1)
    expect(response).to be_a(Enumerator)
    expect(response.next).to be_a(Hash)
    expect(response.next).to be_a(Hash)
  end

  it 'Can get resource controller' do
    resource = described_class.new(:api_key => api_key).resource
    expect(resource).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::ResourceController)
    manager = resource.controller
    expect(manager).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::ResourceController::Controller)
    response = manager.collection('list_resource_instances', :limit => 2)
    expect(response).to be_a(Enumerator)
    expect(response.next).to be_a(Hash)
  end

  it 'Can get resource manager' do
    resource = described_class.new(:api_key => api_key).resource
    expect(resource).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::ResourceController)
    manager = resource.manager
    expect(manager).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::ResourceController::Manager)
    response = manager.collection('list_resource_groups')
    expect(response).to be_a(Enumerator)
    expect(response.next).to be_a(Hash)
  end

  it 'Raises error with non-existent method.' do
    bad_method = :list_instancess

    expect { vpc.request(bad_method) }.to raise_error(StandardError, 'IbmVpc::VpcV1 does not contain a method list_instancess')
    expect { vpc.collection(bad_method).first }.to raise_error(StandardError, 'IbmVpc::VpcV1 does not contain a method list_instancess')
  end

  it 'Raises error in collection when method is not a list.' do
    expect { vpc.collection(:get_instance) }.to raise_error(StandardError, 'Provided call_back get_instance does not start with list. This method is for paginating list methods.')
  end

  it 'Instances is callable' do
    instances = vpc.instances
    expect(instances).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::Instances)
    expect(instances).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf)
    expect(instances).to respond_to(:all)
    expect(instances.all(:limit => 1)).to be_a(Enumerator)
    expect(instances.all.first).to be_a(Hash)
  end

  it 'Instance is callable' do
    expect(vpc.instances).to respond_to(:instance).with(1).argument

    # Request a list of instances and limit to 1 result. Test each instance to see if it is running.
    instance_hash = nil
    vpc.instances.all(:limit => 1).each do |inst|
      instance_hash = inst if inst[:status].downcase == 'running'
      break if instance_hash.nil? == false
    end
    expect(instance_hash).not_to be_nil, 'Unable to find a running VM in VPC Cloud.'

    # Test the returned hash is what we expect.
    expect(instance_hash).to be_a(Hash)
    expect(instance_hash).to have_key(:id)

    # Test that the same instance can be called using instances.instance.
    instance = vpc.instances.instance(instance_hash[:id])
    expect(instance).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::Instance)
    expect(instance).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf)
    expect(instance).to have_key(:id)

    # Test actions can be called.
    expect(instance).to respond_to(:actions)
    expect(instance.actions).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::InstanceActions)
    expect(instance.actions).to be_a(ManageIQ::Providers::IbmCloud::CloudTools::Sdk::Leaf)

    # Test that instance actions are created properly.
    start_action = instance.actions.start
    expect(start_action).to be_a(Hash)
    expect(start_action).to have_key(:type)
    expect(start_action[:type]).to eq('start')
  end
end
