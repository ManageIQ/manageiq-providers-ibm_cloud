require 'logger'

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Vm do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => 'IBMCVS_API_KEY')
    end
  end

  let(:vm) do
    ems_ref = SecureRandom.uuid
    FactoryBot.create(:vm_ibm_cloud_vpc, :ext_management_system => ems, :ems_ref => ems_ref)
  end

  context "is_available?" do
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
      require "ibm_cloud_sdk_core"
      allow(vm).to receive(:with_provider_connection).and_yield(connection)
    end

    let(:connection) { double("IbmVpc::VpcV1") }

    it 'stops the virtual machine' do
      expect(connection).to receive(:create_instance_action).with(:instance_id => vm.ems_ref, :type => "stop")

      get_instance_response = IBMCloudSdkCore::DetailedResponse.new(:body => {"status" => "stopped"}, :status => 200, :headers => {})
      expect(connection).to receive(:get_instance).with(:id => vm.ems_ref).and_return(get_instance_response)

      vm.raw_stop
      expect(vm.reload.power_state).to eq('off')
    end

    it 'starts the virtual machine' do
      expect(connection).to receive(:create_instance_action).with(:instance_id => vm.ems_ref, :type => "start")

      get_instance_response = IBMCloudSdkCore::DetailedResponse.new(:body => {"status" => "running"}, :status => 200, :headers => {})
      expect(connection).to receive(:get_instance).with(:id => vm.ems_ref).and_return(get_instance_response)

      vm.raw_start
      expect(vm.reload.power_state).to eq('on')
    end

    it 'reboots the virtual machine' do
      expect(connection).to receive(:create_instance_action).with(:instance_id => vm.ems_ref, :type => "reboot", :force => false)

      get_instance_response = IBMCloudSdkCore::DetailedResponse.new(:body => {"status" => "running"}, :status => 200, :headers => {})
      expect(connection).to receive(:get_instance).with(:id => vm.ems_ref).and_return(get_instance_response)

      vm.raw_reboot_guest
      expect(vm.reload.power_state).to eq('on')
    end

    it 'force reboot the virtual machine' do
      expect(connection).to receive(:create_instance_action).with(:instance_id => vm.ems_ref, :type => "reboot", :force => true)

      get_instance_response = IBMCloudSdkCore::DetailedResponse.new(:body => {"status" => "running"}, :status => 200, :headers => {})
      expect(connection).to receive(:get_instance).with(:id => vm.ems_ref).and_return(get_instance_response)

      vm.raw_reset
      expect(vm.reload.power_state).to eq('on')
    end
  end
end
