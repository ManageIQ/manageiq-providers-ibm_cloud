# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  include Spec::Support::EmsRefreshHelper

  let(:ems) do
    api_key = Rails.application.secrets.ibm_cloud_vpc[:api_key]
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => api_key)
    end
  end

  # If recording a new VCR note that this method, assert_ems_counts and assert_specific_vm will need to be updated.
  # The first time run there may be failures for key_pairs in VM or IP Address in assert_specific_floating_ip.
  # This has to do with obscuring code in the vcr config. Try again to see if running this with a recorded VCR fixes the issue.
  it "tests the refresh" do
    2.times do
      with_vcr { ems.refresh }
      ems.reload

      assert_ems_counts
      assert_specific_vm
      assert_specific_flavor
      assert_specific_resource_group
      assert_specific_security_group
      assert_specific_cloud_volume_type
      assert_specific_cloud_subnet
      assert_specific_floating_ip
      assert_vm_labels
    end
  end

  context "targeted refresh" do
    before { with_vcr { ems.refresh } }

    context "vm target" do
      let(:target) { ems.vms.find_by(:ems_ref => "0757_81687d4a-4676-4eeb-9fd7-55f9c7fffb69") }

      it "with a deleted vm" do
        connection = double("IbmCloud::CloudTool")
        allow(ems).to receive(:connect).and_return(connection)
        expect(connection).to receive(:request)
          .with(:get_instance, :id => target.ems_ref)
          .and_raise(
            IBMCloudSdkCore::ApiException.new(
              :code                  => 404,
              :error                 => "Error: Instance not found",
              :transaction_id        => "1234",
              :global_transaction_id => "5678"
            )
          )

        EmsRefresh.refresh(target)

        expect(target.reload).to be_archived
      end

      it "doesn't impact other inventory" do
        assert_inventory_not_changed do
          with_vcr("vm_target") { EmsRefresh.refresh(target) }
        end
      end
    end
  end

  # Test that the refresh has persisted the same number of items as expected from the Cloud.
  def assert_ems_counts
    # Cloud Manager
    cloud_manager = {
      :availability_zones => 3,
      :key_pairs          => 2,
      :miq_templates      => 57,
      :resource_groups    => 3,
      :vms                => 6,
    }.freeze
    check_counts(ems, cloud_manager)

    # Network Manager
    network_manager = {
      :cloud_networks  => 2,
      :cloud_subnets   => 4,
      :floating_ips    => 5,
      :security_groups => 2,
    }.freeze
    check_counts(ems, network_manager)

    # Storage Manager
    storage_manger = {
      :cloud_volume_types => 4,
      :cloud_volumes      => 15,
    }
    check_counts(ems, storage_manger)
  end

  # Test a specific VMs's configuration.
  def assert_specific_vm
    vm = check_resource_fetch(ems, :vms, '0777_249ba858-a4eb-4f2c-ba6c-72254a781d0d')

    check_count(vm, :ipaddresses, 1)
    expect(vm.availability_zone.name).to eq('us-east-3')
    expect(vm.cpu_total_cores).to eq(2)
    expect(vm.hardware.memory_mb).to eq(16_384)
    expect(vm.hardware.cpu_total_cores).to eq(2)
    expect(vm.hardware.cpu_sockets).to eq(2)
    expect(vm.hardware.bitness).to eq(64)
    expect(vm.operating_system[:product_name]).to eq('linux_redhat')
    expect(vm.flavor.name).to eq('mx2-2x16')
    expect(vm.raw_power_state).to eq('stopped')
    expect(vm.power_state).to eq('off')
    expect(vm.security_groups.count).to eq(1)

    ## linking key pairs to vms
    expect(vm.key_pairs.count).to eq(1)
    expect(vm.key_pairs.first.name).to eq('random_key_0')
    expect(vm.key_pairs.first.fingerprint).to eq('SHA256:xxxxxxx')

    # Check that ems_ref is not nil and has a value which follows the guidance in https://cloud.ibm.com/apidocs/vpc#list-keys
    expect(vm.key_pairs.first.ems_ref).to_not be_nil
    expect(vm.key_pairs.first.ems_ref).to match(/^[-0-9a-z_]{1,64}/)
  end

  def assert_specific_flavor
    flavor = check_resource_fetch(ems, :flavors, 'mx2-2x16')
    expect(flavor).to have_attributes(
      :name      => 'mx2-2x16',
      :cpus      => 2,
      :cpu_cores => 2,
      :memory    => 18_432,
      :ems_ref   => 'mx2-2x16',
      :type      => 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::Flavor',
      :enabled   => true
    )
  end

  # Test a resource_group record is properly persisted.
  def assert_specific_resource_group
    resource = check_resource_fetch(ems, :resource_groups, '29b1dd25de2d40b5ae5bd5f719f30db8')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::ResourceGroup'
    check_attribute_values(resource, '29b1dd25de2d40b5ae5bd5f719f30db8', class_type, 'camc-test')
  end

  # Test a resource_group record is properly persisted.
  def assert_vm_labels
    vm = check_resource_fetch(ems, :vms, '0777_f73e8687-3813-465f-99df-ba6e4ee8f289')
    check_count(vm, :labels, 4)
  end

  # Test a security_group record is properly persisted.
  def assert_specific_security_group
    resource = check_resource_fetch(ems, :security_groups, 'r014-e4be0c69-6df6-4464-a9bc-384e4179ea1b')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::SecurityGroup'
    check_attribute_values(resource, 'r014-e4be0c69-6df6-4464-a9bc-384e4179ea1b', class_type, 'backup-deglazed-bagful-deflation')

    cloud_network = check_resource_fetch(ems, :cloud_networks, 'r014-0fa2acc6-2a41-4f2b-9c89-bcea07cdcbc3')
    check_relationship(resource, :cloud_network_id, cloud_network)
  end

  # Test a cloud_volume_type record is properly persisted.
  def assert_specific_cloud_volume_type
    resource = check_resource_fetch(ems, :cloud_volume_types, 'general-purpose')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolumeType'
    check_attribute_values(resource, 'general-purpose', class_type, 'general-purpose', {:description => 'tiered'})
  end

  # Test the components of a cloud subnet.
  def assert_specific_cloud_subnet
    cloud_subnet = check_resource_fetch(ems, :cloud_subnets, '0757-ef523a2f-5356-42ff-8a78-9325509465b9')

    # Test cloud_network relationship.
    cloud_network = check_resource_fetch(ems, :cloud_networks, 'r014-0fa2acc6-2a41-4f2b-9c89-bcea07cdcbc3')
    check_relationship(cloud_subnet, :cloud_network_id, cloud_network)

    # Test availability_zone relationship.
    availability_zone = check_resource_fetch(ems, :availability_zones, 'us-east-1')
    check_relationship(cloud_subnet, :availability_zone_id, availability_zone)

    # Test remaining fields.
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet'
    ip_version = 'ipv4'

    additional_values = {:cidr => '127.0.0.0/24', :ip_version => ip_version, :network_protocol => ip_version}
    check_attribute_values(cloud_subnet, '0757-ef523a2f-5356-42ff-8a78-9325509465b9', class_type, 'b-subneet-washington-dc-1', additional_values)
  end

  # Test a floating_ip record.

  def assert_specific_floating_ip
    floating_ip = check_resource_fetch(ems, :floating_ips, 'r014-1892eee4-79ab-4d26-8efd-4c5759fc03fc')

    vm = check_resource_fetch(ems, :vms, '0777_a9ee9e6a-231a-4a3c-b9cb-fc83d25114a2')
    check_relationship(floating_ip, :vm_id, vm)

    # Find the network ports using the vm ems_ref which is stored as device_ref on network_ports.
    # Assumes only 1 network port is on the VM.
    network_port = check_resource_fetch(vm, :network_ports, '0777_a9ee9e6a-231a-4a3c-b9cb-fc83d25114a2', :key => :device_ref)
    check_relationship(floating_ip, :network_port_id, network_port)

    internal_ip_address = vm.ipaddresses.first
    class_type = "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::FloatingIp"
    values = {:type => class_type, :ems_ref => 'r014-1892eee4-79ab-4d26-8efd-4c5759fc03fc', :status => 'available'}
    expect(floating_ip).to have_attributes(values)

    check_obscured_ip(floating_ip, :address, '150.239.208.80')
    check_obscured_ip(floating_ip, :fixed_ip_address, internal_ip_address.to_s)
  end

  # IP Addresses are obscured when they are saved to VCR. This may fail on the first recording.
  # @param resource [ApplicationRecord]
  # @param method [Symbol] The method name to retrieve the table field.
  # @param address [String] The IP Address to test. If the ip address is the one found in the cloud it will be converted.
  # @return [void]
  def check_obscured_ip(resource, method, address)
    expected = address.match?(/127.0.0/) ? address : "127.0.0.#{address.split('.')[-1]}"
    actual = resource.send(method.to_sym)
    expect(actual).to eq(expected), "Obscured ip address #{resource.class.name}.#{method} expected #{expected} received #{actual}"
  end

  # Fetch an ApplicationRecord using the ems_ref. Test that the method exists and an item with ems_ref is present.
  # @param mgmt [VPC] The VPC EMS.
  # @param method [Symbol] The method to use to call the association record.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param key [Symbol] The key to use to find the record.
  # @return [ApplicationRecord] The result of the find.
  def check_resource_fetch(mgmt, method, ems_ref, key: :ems_ref)
    expect(mgmt).to respond_to(method.to_sym), "ems does not respond to #{method}"

    resource = mgmt.send(method.to_sym).find_by(key.to_sym => ems_ref)
    expect(resource).not_to be_nil, "#{mgmt.class.name}.#{method} with #{key} #{ems_ref} was not found in db."
    resource
  end

  # Compare the attributes of 'resource' to the provided values.
  # @param resource [ApplicationRecord]
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param class_type [String] The class that the resource is supposed to represent.
  # @param name [String] The value of the name attribute.
  # @param additional_values [Hash] Values that are unique to the class.
  # @return [void]
  def check_attribute_values(resource, ems_ref, class_type, name = nil, additional_values = {})
    default_values = {:ems_ref => ems_ref, :type => class_type.to_s}
    default_values[:name] = name unless name.nil?
    values = default_values.merge(additional_values)
    expect(resource).to have_attributes(values)
  end

  # Check that a relationship is properly persisted.
  # @param resource [ApplicationRecord] The instance that holds the has_many relationship.
  # @param fk_key [String] The foreign key field to verify against.
  # @param assoc [ApplicationRecord] The other side of the relationship.
  # @return [void]
  def check_relationship(resource, fk_name, assoc)
    fk_value = resource.send(fk_name.to_sym)
    pk_assoc = assoc.id
    expect(fk_value).to eq(pk_assoc), "Association between #{resource.class.name} id #{fk_value} does not match expected #{assoc.class.name} id #{pk_assoc}"
  end

  # Check that a relationship has the expected number of items.
  # @param resource [ApplicationRecord] The instance that holds the relationship.
  # @param method [Symbol] The method name to retrieve the relationship.
  # @param expected [Integer] The expected number of items.
  # @return [void]
  def check_count(resource, method, expected)
    expect(resource).to respond_to(method.to_sym), "ems does not respond to #{method}"
    actual = resource.send(method.to_sym).count
    expect(actual).to eq(expected), "Resource #{resource.class.name}.#{method} has #{actual} items expected #{expected}"
  end

  # Test a number of resource counts.
  # @param resource [ApplicationRecord] The instance that holds the relationship.
  # @param resources [Hash<Symbol, Integer>] A hash where the key represents a method and the value represents the expected count.
  # @return [void]
  def check_counts(resource, resources)
    resources.each_pair { |key, value| check_count(resource, key, value) }
  end
end
