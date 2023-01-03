namespace :vcr do
  namespace :vpc do
    require 'ibm_cloud_sdk_core'
    require 'ibm_cloud_resource_controller'
    require 'ibm_vpc'

    def with_retry(retry_count: 30, retry_sleep: 10)
      retry_count.times do
        yield
        sleep(retry_sleep)
      rescue IBMCloudSdkCore::ApiException
        break
      end
    end

    base_dir = ManageIQ::Providers::IbmCloud::Engine.root.join("spec")
    cass_dir = base_dir.join("vcr_cassettes/manageiq/providers/ibm_cloud")
    spec_dir = base_dir.join("models/manageiq/providers/ibm_cloud")

    # Prerequisites:
    # 1. Log in with IBM Cloud CLI i.e. `ibmcloud login -sso`
    # 2. Place IBM Cloud API key in secrets config
    desc "Generate VPC refresher VCR"
    task :rerecord => :environment do
      cass_dir.glob("vpc/cloud_manager/**/*.yml").each(&:delete)

      begin
        apikey = YAML.load_file("config/secrets.yml").dig("test", "ibm_cloud_vpc", "api_key")
      rescue NoMethodError
        raise "IBM Cloud API key not found in secrets config file"
      end
      token = IBMCloudSdkCore::IAMTokenManager.new(:apikey => apikey).access_token
      auth = IBMCloudSdkCore::BearerTokenAuthenticator.new(:bearer_token => token)

      connection = IbmVpc::VpcV1.new(:authenticator => auth, :service_url => "https://ca-tor.iaas.cloud.ibm.com/v1")
      resource_controller = IbmCloudResourceController::ResourceControllerV2.new(:authenticator => auth)

      # Create resources
      begin
        default_resource_group_id = `ibmcloud resource group default --id | tr -d '\n'`
        cloud_db_id = resource_controller.create_resource_instance(
          :name             => 'rake-db',
          :target           => 'bluemix-ca-tor',
          :resource_group   => default_resource_group_id,
          :resource_plan_id => 'databases-for-postgresql-standard'
        ).result['id']
        status = resource_controller.get_resource_instance(:id => cloud_db_id).result['state']
        puts "Provisioning cloud database..."
        until status == 'active'
          sleep(10)
          status = resource_controller.get_resource_instance(:id => cloud_db_id).result['state']
        end
        puts "Provisioned cloud database"
      rescue => error
        raise error
      end

      network_id = connection.create_vpc(:name => 'rake-network').result['id']
      subnet_prototype = {
        :vpc             => {
          :id => network_id
        },
        :name            => 'rake-subnet',
        :zone            => {
          :name => 'ca-tor-1'
        },
        :ipv4_cidr_block => '10.249.1.0/24'
      }
      subnet_id = connection.create_subnet(:subnet_prototype => subnet_prototype).result['id']
      volume_prototype = {
        :profile  => {
          :name => '5iops-tier'
        },
        :zone     => {
          :name => 'ca-tor-1'
        },
        :name     => 'rake-vol',
        :capacity => 10
      }
      volume_id = connection.create_volume(:volume_prototype => volume_prototype).result['id']

      `ssh-keygen -f temp -t rsa -P ""`
      ssh_key = File.read("temp.pub")
      auth_key_id = connection.create_key(:public_key => ssh_key, :name => 'rake-key').result['id']
      `rm temp*`

      security_group_id = connection.create_security_group(:vpc => {:id => network_id}, :name => 'rake-group').result['id']

      instance_prototype = {
        :primary_network_interface => {
          :name            => 'eth0',
          :subnet          => {
            :id => subnet_id
          },
          :security_groups => [{
            :id => security_group_id
          }]
        },
        :name                      => 'rake-instance',
        :zone                      => {
          :name => 'ca-tor-1'
        },
        :vpc                       => {
          :id => network_id
        },
        :profile                   => {
          :name => "bx2-2x8"
        },
        :image                     => {
          :id => 'r038-ea70cf5b-93f0-4871-a31e-f0030484149e'
        },
        :keys                      => [
          {
            :id => auth_key_id
          }
        ],
        :volume_attachments        => [],
        :boot_volume_attachment    => {
          :volume => {
            :name    => 'rake-instance-boot',
            :profile => {
              :name => 'general-purpose'
            }
          }
        }
      }
      instance_id = connection.create_instance(:instance_prototype => instance_prototype).result['id']
      status = connection.get_instance(:id => instance_id).result['status']
      until status == 'running'
        sleep(10)
        status = connection.get_instance(:id => instance_id).result['status']
      end

      network_interface_id = connection.list_instance_network_interfaces(:instance_id => instance_id).result["network_interfaces"][0]["id"]
      floating_ip_prototype = {:name => 'rake-floating-ip', :target => {:id => network_interface_id}}
      floating_ip_id = connection.create_floating_ip(:floating_ip_prototype => floating_ip_prototype).result['id']
      status = connection.get_floating_ip(:id => floating_ip_id).result['status']
      until status == 'available'
        sleep(10)
        status = connection.get_floating_ip(:id => floating_ip_id).result['status']
      end

      load_balancer_listener_prototype = {
        :protocol => "http",
        :port     => 8080,
        :port_min => 8080,
        :port_max => 8080
      }
      load_balancer_health_monitor_prototype = {
        :delay       => 5,
        :max_retries => 2,
        :timeout     => 2,
        :type        => "http",
        :url_path    => "/"
      }
      network_interface_addr = connection.get_instance_network_interface(:instance_id => instance_id, :id => network_interface_id).result["primary_ipv4_address"]
      load_balancer_pool_member_prototype = {
        :port   => 80,
        :target => {:address => network_interface_addr}
      }
      load_balancer_pool_prototype = {
        :algorithm      => "round_robin",
        :health_monitor => load_balancer_health_monitor_prototype,
        :protocol       => "http",
        :members        => [load_balancer_pool_member_prototype],
        :name           => "rake-pool"
      }
      load_balancer_prototype = {
        :is_public => true,
        :subnets   => [{:id => subnet_id}],
        :listeners => [load_balancer_listener_prototype],
        :name      => "rake-balancer",
        :pools     => [load_balancer_pool_prototype]
      }
      load_balancer_id = connection.create_load_balancer(load_balancer_prototype).result["id"]
      status = connection.get_load_balancer(:id => load_balancer_id).result['provisioning_status']
      until status == 'active'
        sleep(10)
        status = connection.get_load_balancer(:id => load_balancer_id).result['provisioning_status']
      end

      network_acl_rule_prototype = {
        :name        => "rake-acl-rule",
        :action      => "allow",
        :source      => "0.0.0.0/0",
        :destination => "0.0.0.0/0",
        :direction   => "inbound",
        :protocol    => "all"
      }
      network_acl_prototype = {
        :vpc   => {:id => network_id},
        :name  => "rake-acl",
        :rules => [network_acl_rule_prototype]
      }
      network_acl_id = connection.create_network_acl(:network_acl_prototype => network_acl_prototype).result["id"]

      vpn_gateway_prototype = {
        :subnet => {:id => subnet_id},
        :name   => "rake-gateway"
      }
      vpn_gateway_id = connection.create_vpn_gateway(:vpn_gateway_prototype => vpn_gateway_prototype).result["id"]
      status = connection.get_vpn_gateway(:id => vpn_gateway_id).result['status']
      until status == 'available'
        sleep(10)
        status = connection.get_vpn_gateway(:id => vpn_gateway_id).result['status']
      end

      vpn_connection_prototype = {
        :name         => "rake-connection",
        :peer_address => "169.21.50.5",
        :psk          => "abc123"
      }
      connection.create_vpn_gateway_connection(:vpn_gateway_id                   => vpn_gateway_id,
                                               :vpn_gateway_connection_prototype => vpn_connection_prototype)

      # Generate VCRs
      spec_file = spec_dir.join("vpc/cloud_manager/refresher_spec.rb")
      `bundle exec rspec #{spec_file} --tag full_refresh`

      instance_prototype[:name] = 'rake-instance2'
      instance_prototype[:boot_volume_attachment][:volume][:name] = 'rake-instance2-boot'
      target_instance_id = connection.create_instance(:instance_prototype => instance_prototype).result['id']
      status = connection.get_instance(:id => target_instance_id).result['status'] until status == 'running'

      `bundle exec rspec #{spec_file} --tag target_vm`

      # Cleanup resources
    ensure
      resource_controller.delete_resource_instance(:id => cloud_db_id) unless cloud_db_id.nil?
      connection.delete_load_balancer(:id => load_balancer_id) unless load_balancer_id.nil?
      with_retry { connection.get_load_balancer(:id => load_balancer_id) }

      connection.delete_floating_ip(:id => floating_ip_id) unless floating_ip_id.nil?
      with_retry { connection.get_floating_ip(:id => floating_ip_id) }

      connection.delete_volume(:id => volume_id) unless volume_id.nil?
      connection.delete_instance(:id => instance_id) unless instance_id.nil?
      connection.delete_instance(:id => target_instance_id) unless target_instance_id.nil?
      with_retry { connection.get_instance(:id => instance_id) }
      with_retry { connection.get_instance(:id => target_instance_id) }

      connection.delete_vpn_gateway(:id => vpn_gateway_id) unless vpn_gateway_id.nil?
      with_retry { connection.get_vpn_gateway(:id => vpn_gateway_id) }

      connection.delete_subnet(:id => subnet_id) unless subnet_id.nil?
      with_retry { connection.get_subnet(:id => subnet_id) }

      connection.delete_network_acl(:id => network_acl_id) unless network_acl_id.nil?
      connection.delete_key(:id => auth_key_id) unless auth_key_id.nil?
      connection.delete_vpc(:id => network_id) unless network_id.nil?
    end
  end
end
