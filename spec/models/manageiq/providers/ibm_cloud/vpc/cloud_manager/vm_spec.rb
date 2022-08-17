# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm, :vcr do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => 'IBM_CLOUD_VPC_API_KEY')
    end
  end

  let(:vm) do
    FactoryBot.create(:vm_ibm_cloud_vpc, :ext_management_system => ems)
  end

  context "#supports?" do
    let(:power_state_on)        { "running" }
    let(:power_state_suspended) { "stopped" }

    context "with :start" do
      let(:state) { :start }
      include_examples "Vm operation is available when not powered on"
    end

    context "with :stop" do
      let(:state) { :stop }
      include_examples "Vm operation is available when powered on"
    end

    context "with :reboot_guest" do
      let(:state) { :reboot_guest }
      include_examples "Vm operation is available when powered on"
    end

    context "with :reset" do
      let(:state) { :reset }
      include_examples "Vm operation is available when powered on"
    end
  end

  describe 'power operations' do
    before(:each) do
      allow(vm).to receive(:provider_object).and_return(instance)
    end

    let(:parent) do
      vpc = double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
      allow(vpc).to receive(:logger).and_return(Logger.new(nil))
      allow(vpc).to receive_messages(:cloudtools => nil, :region => nil, :version => nil)
      vpc
    end

    let(:actions) do
      actions = ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::InstanceActions.new(:vpc => parent, :instance_id => nil)
      allow(actions).to receive(:create).and_return({:this => 'mock'})
      actions
    end

    let(:instance) do
      instance = ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::Instance.new(:vpc => parent, :data => {})
      allow(instance).to receive(:refresh) { instance.merge!({:id => 'mock_id', :name => 'Test instance', :status => 'running'}) }
      allow(instance).to receive(:actions).and_return(actions)
      instance.refresh
      instance
    end

    it 'stops the virtual machine' do
      allow(instance).to receive(:status).and_return('running', 'stopping', 'stopped')
      vm.raw_stop
      expect(vm.power_state).to eq('off')
    end

    it 'starts the virtual machine' do
      allow(instance).to receive(:status).and_return('stopped', 'starting', 'running')
      vm.raw_start
      expect(vm.power_state).to eq('on')
    end

    it 'reboots the virtual machine' do
      allow(instance).to receive(:status).and_return('running', 'stopping', 'stopped', 'starting', 'running')
      vm.raw_reboot_guest
      expect(vm.power_state).to eq('on')
    end

    it 'force reboot the virtual machine' do
      allow(instance).to receive(:status).and_return('running', 'stopping', 'stopped', 'starting', 'running')
      vm.raw_reset
      expect(vm.power_state).to eq('on')
    end
  end

  describe '#raw_destroy' do
    before(:each) do
      allow(vm).to receive(:provider_object).and_return(instance)
    end

    let(:parent) do
      vpc = double("ManageIQ::Providers::IbmCloud::CloudTools::Vpc")
      allow(vpc).to receive(:logger).and_return(Logger.new(nil))
      allow(vpc).to receive_messages(:cloudtools => nil, :region => nil, :version => nil, :request => nil)
      vpc
    end

    let(:instance) do
      instance = ManageIQ::Providers::IbmCloud::CloudTools::VpcSdk::Instance.new(:vpc => parent, :data => {})
      allow(instance).to receive(:refresh) { instance.merge!({:id => 'mock_id', :name => 'Test instance', :status => 'running'}) }
      instance.refresh
      instance
    end

    it 'deletes the virtual machine' do
      expect(parent).to receive(:request).with(:delete_instance, :id => instance.id)
      vm.raw_destroy
    end
  end
end
