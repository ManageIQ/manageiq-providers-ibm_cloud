describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Vm do
  let(:ems) do
    FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud, :provider_region => "us-south")
  end
  let(:vm) { FactoryBot.create(:vm_ibm_cloud_power_virtual_servers, :ext_management_system => ems) }

  let(:power_state_on)        { "ACTIVE" }
  let(:power_state_suspended) { "SHUTOFF" }

  context "is_available?" do
    context "with :start" do
      let(:state) { :start }
      include_examples "Vm operation is available when not powered on"
    end

    context "with :stop" do
      let(:state) { :stop }
      include_examples "Vm operation is available when powered on"
    end

    context "with :shutdown_guest" do
      let(:state) { :shutdown_guest }
      include_examples "Vm operation is not available"
    end

    context "with :standby_guest" do
      let(:state) { :standby_guest }
      include_examples "Vm operation is not available"
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

  context "supports VM console access?" do
    it 'supports console access if powered on' do
      vm.update(:raw_power_state => power_state_on)
      expect(vm.supports?(:html5_console)).to be_truthy
    end

    it 'no console access if powered off' do
      vm.update(:raw_power_state => power_state_suspended)
      expect(vm.supports?(:html5_console)).to be_falsey
    end

    it 'no console access if orphaned' do
      vm.update(:ems_id => nil)
      expect(vm.supports?(:html5_console)).to be_falsey
    end

    it 'no console access if archived' do
      vm.update(:ems_id => nil, :storage_id => nil)
      expect(vm.supports?(:html5_console)).to be_falsey
    end
  end

  context "supports management console access?" do
    it 'supports console access if powered on' do
      vm.update(:raw_power_state => power_state_on)
      expect(vm.supports?(:native_console)).to be_truthy
    end

    it 'no console access if powered off' do
      vm.update(:raw_power_state => power_state_suspended)
      expect(vm.supports?(:native_console)).to be_truthy
    end

    it 'no console access if orphaned' do
      vm.update(:ems_id => nil)
      expect(vm.supports?(:native_console)).to be_falsey
    end

    it 'no console access if archived' do
      vm.update(:ems_id => nil, :storage_id => nil)
      expect(vm.supports?(:native_console)).to be_falsey
    end
  end
end
