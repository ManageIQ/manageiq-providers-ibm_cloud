# frozen_string_literal: true

describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::Refresher do
  include Spec::Support::EmsRefreshHelper

  let(:ems) do
    api_key = Rails.application.secrets.ibm_cloud_vpc[:api_key]
    FactoryBot.create(:ems_ibm_cloud_vpc, :provider_region => "ca-tor").tap do |ems|
      ems.authentications << FactoryBot.create(:authentication, :auth_key => api_key)
    end
  end

  # If recording a new VCR note that this method and assert_specific_vm will need to be updated.
  # The first time run there may be failures for key_pairs in VM or IP Address in assert_specific_floating_ip.
  # This has to do with obscuring code in the vcr config. Try again to see if running this with a recorded VCR fixes the issue.
  context "full refresh" do
    it "tests the refresh", :full_refresh => true do
      inventory = nil
      2.times do
        with_vcr { ems.refresh }
        inventory ? assert_inventory_not_changed { inventory } : inventory = serialize_inventory
        ems.reload

        assert_specific_flavor
        assert_specific_security_group
        assert_specific_cloud_volume
        assert_specific_cloud_volume_type
        assert_specific_cloud_subnet
        assert_specific_floating_ip
        assert_specific_network_acl_rule
        assert_specific_load_balancer
        assert_specific_load_balancer_pool
        assert_specific_cloud_database
        assert_specific_cloud_database_flavor
        assert_specific_vm
      end
    end
  end

  context "targeted refresh" do
    before { with_vcr { ems.refresh } }

    context "vm target", :target_vm => true do
      let(:target) { ems.vms.find_by(:name => "rake-instance") }

      it "with a deleted vm" do
        connection = double("IbmCloud::CloudTool")
        vpc = double("IbmCloud::CloudTool::VPC")
        allow(ems).to receive(:connect).and_return(connection)
        allow(connection).to receive(:vpc).with(:region => ems.provider_region).and_return(vpc)
        expect(vpc).to receive(:request)
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

  # Test a specific VMs's configuration.
  def assert_specific_vm
    vm = ems.vms.find_by(:name => 'rake-instance')
    check_count(vm, :ipaddresses, 2)
    expect(vm.availability_zone.name).to eq('ca-tor-1')
    expect(vm.cpu_total_cores).to eq(2)
    expect(vm.hardware.memory_mb).to eq(8_192)
    expect(vm.hardware.cpu_total_cores).to eq(2)
    expect(vm.hardware.cpu_sockets).to eq(2)
    expect(vm.hardware.bitness).to eq(64)
    expect(vm.operating_system[:product_name]).to eq('linux_debian')
    expect(vm.flavor.name).to eq('bx2-2x8')
    expect(vm.raw_power_state).to eq('running')
    expect(vm.power_state).to eq('on')
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
    flavor = check_resource_fetch(ems, :flavors, 'bx2-2x8')
    expect(flavor).to have_attributes(
      :name            => 'bx2-2x8',
      :cpu_total_cores => 2,
      :memory          => 8_192,
      :ems_ref         => 'bx2-2x8',
      :type            => 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::Flavor',
      :enabled         => true
    )
  end

  # Test a resource_group record is properly persisted.
  def assert_specific_resource_group
    resource = check_resource_fetch(ems, :resource_groups, '29b1dd25de2d40b5ae5bd5f719f30db8')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::CloudManager::ResourceGroup'
    check_attribute_values(resource, '29b1dd25de2d40b5ae5bd5f719f30db8', class_type, 'camc-test')
  end

  # Test a vm_label record is properly persisted.
  def assert_vm_labels
    vm = ems.vms.find_by(:name => 'rake-instance')
    check_count(vm, :labels, 1)
  end

  # Test a security_group record is properly persisted.
  def assert_specific_security_group
    resource = ems.security_groups.find_by(:name => 'rake-group')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::SecurityGroup'
    check_attribute_values(resource, class_type, 'rake-group')

    cloud_network = ems.cloud_networks.find_by(:name => 'rake-network')
    check_relationship(resource, :cloud_network_id, cloud_network)
  end

  # Test a cloud_volume record is properly persisted.
  def assert_specific_cloud_volume
    resource = ems.cloud_volumes.find_by(:name => 'rake-vol')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolume'
    check_attribute_values(resource, class_type, 'rake-vol', {:size => 10.gigabytes, :status => 'available'})
  end

  # Test a cloud_volume_type record is properly persisted.
  def assert_specific_cloud_volume_type
    resource = check_resource_fetch(ems, :cloud_volume_types, 'general-purpose')
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::StorageManager::CloudVolumeType'
    check_attribute_values(resource, class_type, 'general-purpose', {:description => 'tiered'})
  end

  # Test the components of a cloud subnet.
  def assert_specific_cloud_subnet
    cloud_subnet = ems.cloud_subnets.find_by(:name => 'rake-subnet')

    # Test cloud_network relationship.
    cloud_network = ems.cloud_networks.find_by(:name => 'rake-network')
    check_relationship(cloud_subnet, :cloud_network_id, cloud_network)

    # Test availability_zone relationship.
    availability_zone = check_resource_fetch(ems, :availability_zones, 'ca-tor-1')
    check_relationship(cloud_subnet, :availability_zone_id, availability_zone)

    # Test remaining fields.
    class_type = 'ManageIQ::Providers::IbmCloud::VPC::NetworkManager::CloudSubnet'
    ip_version = 'ipv4'

    additional_values = {:cidr => '127.0.0.0/24', :ip_version => ip_version, :network_protocol => ip_version}
    check_attribute_values(cloud_subnet, class_type, 'rake-subnet', additional_values)
  end

  # Test a floating_ip record.

  def assert_specific_floating_ip
    vm = ems.vms.find_by(:name => 'rake-instance')
    floating_ip = ems.floating_ips.find_by(:vm_id => vm.id)

    check_relationship(floating_ip, :vm_id, vm)

    # Find the network ports using the vm ems_ref which is stored as device_ref on network_ports.
    # Assumes only 1 network port is on the VM.
    network_port = check_resource_fetch(vm, :network_ports, 'eth0', :key => :name)
    check_relationship(floating_ip, :network_port_id, network_port)

    internal_ip_address = vm.ipaddresses.first
    class_type = "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::FloatingIp"
    values = {:type => class_type, :status => 'available'}
    expect(floating_ip).to have_attributes(values)

    check_obscured_ip(floating_ip, :fixed_ip_address, internal_ip_address.to_s)
  end

  def assert_specific_cloud_database
    cloud_database = ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabase.find_by(:name => "rake-db")
    expect(cloud_database).to have_attributes(
      :name      => "rake-db",
      :status    => "active",
      :db_engine => "12"
    )
  end

  def assert_specific_cloud_database_flavor
    cloud_database_flavor = ManageIQ::Providers::IbmCloud::VPC::CloudManager::CloudDatabaseFlavor.find_by(:name => "medium")
    expect(cloud_database_flavor).to have_attributes(
      :ems_ref => "medium",
      :name    => "medium",
      :enabled => true,
      :cpus    => 10,
      :memory  => 42_949_672_960
    )
  end

  def assert_specific_load_balancer
    load_balancer = ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancer.find_by(:name => "rake-balancer")
    expect(load_balancer).to have_attributes(
      :name => "rake-balancer",
      :type => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancer"
    )
    assert_specific_load_balancer_listener(load_balancer.id)
    assert_specific_load_balancer_health_check(load_balancer.id)
  end

  def assert_specific_load_balancer_listener(load_balancer_id)
    load_balancer_listener = ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerListener.find_by(:load_balancer_id => load_balancer_id)
    expect(load_balancer_listener).to have_attributes(
      :load_balancer_protocol   => "http",
      :instance_protocol        => "http",
      :load_balancer_port_range => 8080...8081,
      :type                     => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerListener"
    )
  end

  def assert_specific_load_balancer_pool
    load_balancer_pool = ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerPool.find_by(:name => "rake-pool")
    expect(load_balancer_pool).to have_attributes(
      :name                    => "rake-pool",
      :load_balancer_algorithm => "round_robin",
      :protocol                => "http",
      :type                    => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerPool"
    )
  end

  def assert_specific_load_balancer_health_check(load_balancer_id)
    load_balancer_health_check = ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerHealthCheck.find_by(:load_balancer_id => load_balancer_id)
    expect(load_balancer_health_check).to have_attributes(
      :protocol => "http",
      :url_path => "/",
      :interval => 5,
      :timeout  => 2,
      :type     => "ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancerHealthCheck"
    )
  end

  def assert_specific_network_acl_rule
    network_acl_rule = ems.network_manager.cloud_network_firewall_rules.find_by(:name => "rake-network-rake-acl-rake-acl-rule")
    expect(network_acl_rule).to have_attributes(
      :name             => "rake-network-rake-acl-rake-acl-rule",
      :host_protocol    => "all",
      :direction        => "inbound",
      :source_ip_range  => "127.0.0.0/0",
      :network_protocol => "allow"
    )
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
  def check_attribute_values(resource, class_type, name, additional_values = {})
    default_values = {:type => class_type.to_s, :name => name}
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
end
