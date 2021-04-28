# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher, :vcr => {:allow_playback_repeats => true} do
  let(:ems) do
    api_key = Rails.application.secrets.ibm_cloud_vpc[:api_key]
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "us-east").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => api_key)
    end
  end

  it "tests the refresh" do
    2.times do
      mgmt = ems
      mgmt.refresh
      mgmt.reload

      assert_ems_counts(mgmt)
      assert_specific_vm(mgmt)
      assert_specific_resource_group(mgmt, '29b1dd25de2d40b5ae5bd5f719f30db8', 'camc-test')
      assert_specific_security_group(mgmt, 'r014-e4be0c69-6df6-4464-a9bc-384e4179ea1b', 'backup-deglazed-bagful-deflation')
      assert_specific_cloud_volume_type(mgmt, 'general-purpose', 'tiered')
      assert_specific_cloud_subnet(mgmt, '0757-ef523a2f-5356-42ff-8a78-9325509465b9', 'r014-0fa2acc6-2a41-4f2b-9c89-bcea07cdcbc3', 'us-east-1')
      assert_vm_labels(mgmt, '0777_f73e8687-3813-465f-99df-ba6e4ee8f289', 4)
    end
  end

  # Test that the refresh has persisted the same number of items as expected from the Cloud.
  # @param mgmt [VPC] The VPC EMS.
  # @return [void]
  def assert_ems_counts(mgmt)
    # Cloud Manager
    cloud_manger = {
      :availability_zones => 3,
      :key_pairs          => 2,
      :miq_templates      => 57,
      :resource_groups    => 3,
      :vms                => 6,
    }.freeze
    check_counts(mgmt, cloud_manger)

    # Network Manager
    network_manager = {
      :cloud_networks  => 2,
      :cloud_subnets   => 4,
      :floating_ips    => 4,
      :security_groups => 2,
    }.freeze
    check_counts(mgmt, network_manager)

    # Storage Manager
    storage_manger = {
      :cloud_volume_types => 4,
      :cloud_volumes      => 15,
    }
    check_counts(mgmt, storage_manger)
  end

  # Test a resource_group record is properly persisted.
  # @param mgmt [VPC] The VPC EMS.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param name [String] The expected value of the name attribute.
  # @return [void]
  def assert_specific_resource_group(mgmt, ems_ref, name)
    resource = check_resource_fetch(mgmt, :resource_groups, ems_ref)
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::ResourceGroup'
    check_attribute_values(resource, ems_ref, class_type, name)
  end

  # Test a specific VMs's configuration.
  # @param mgmt [VPC] The VPC EMS.
  # @return [void]
  def assert_specific_vm(mgmt)
    vm = check_resource_fetch(mgmt, :vms, '0777_249ba858-a4eb-4f2c-ba6c-72254a781d0d')

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

  # Test a resource_group record is properly persisted.
  # @param mgmt [VPC] The VPC EMS.
  # @param vm_ref [String] A VM uuid with labels attached to it.
  # @param count [String] The expected number of labels with associated vm_ref VM.
  # @return [void]
  def assert_vm_labels(mgmt, vm_ref, count)
    vm = check_resource_fetch(mgmt, :vms, vm_ref)
    check_count(vm, :labels, count)
  end

  # Test a security_group record is properly persisted.
  # @param mgmt [VPC] The VPC EMS.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param name [String] The expected value of the name attribute.
  # @return [void]
  def assert_specific_security_group(mgmt, ems_ref, name)
    resource = check_resource_fetch(mgmt, :security_groups, ems_ref)
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::SecurityGroup'
    check_attribute_values(resource, ems_ref, class_type, name)
  end

  # Test a cloud_volume_type record is properly persisted.
  # @param mgmt [VPC] The VPC EMS.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param description [String] The expected value of the description attribute.
  def assert_specific_cloud_volume_type(mgmt, ems_ref, description)
    resource = check_resource_fetch(mgmt, :cloud_volume_types, ems_ref)
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolumeType'
    check_attribute_values(resource, ems_ref, class_type, ems_ref, {:description => description})
  end

  # Test the components of a cloud subnet.
  # @param mgmt [VPC] The VPC EMS.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param network_ref [String] The associated VPC uuid.
  # @param zone_ref [String] The name of the zone the subnet is attached to.
  # @return [void]
  def assert_specific_cloud_subnet(mgmt, ems_ref, network_ref, zone_ref)
    cloud_subnet = check_resource_fetch(mgmt, :cloud_subnets, ems_ref)

    # Test cloud_network relationship.
    cloud_network = check_resource_fetch(mgmt, :cloud_networks, network_ref)
    check_relationship(cloud_subnet, :cloud_network_id, cloud_network)

    # Test availability_zone relationship.
    availability_zone = check_resource_fetch(mgmt, :availability_zones, zone_ref)
    check_relationship(cloud_subnet, :availability_zone_id, availability_zone)

    # Test remaining fields.
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet'
    ip_version = 'ipv4'

    additional_values = {:cidr => '127.0.0.0/24', :ip_version => ip_version, :network_protocol => ip_version}
    check_attribute_values(cloud_subnet, ems_ref, class_type, 'b-subneet-washington-dc-1', additional_values)
  end

  # Fetch an ApplicationRecord using the ems_ref. Test that the method exists and an item with ems_ref is present.
  # @param mgmt [VPC] The VPC EMS.
  # @param method [Symbol] The method to use to call the association record.
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @return [ApplicationRecord] The result of the find.
  def check_resource_fetch(mgmt, method, ems_ref)
    expect(mgmt).to respond_to(method.to_sym), "ems does not respond to #{method}"

    resource = mgmt.send(method.to_sym).find_by(:ems_ref => ems_ref)
    expect(resource).not_to be_nil, "#{mgmt.class.name}.#{method} with ems_ref #{ems_ref} was not found in db."
    resource
  end

  # Compare the attributes of 'resource' to the provided values.
  # @param resource [ApplicationRecord]
  # @param ems_ref [String] Value used by the Cloud as a ID.
  # @param class_type [String] The class that the resource is supposed to represent.
  # @param name [String] The value of the name attribute.
  # @param additional_values [Hash] Values that are unique to the class.
  # @return [void]
  def check_attribute_values(resource, ems_ref, class_type, name, additional_values = {})
    default_values = {:ems_ref => ems_ref, :type => class_type, :name => name}
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
