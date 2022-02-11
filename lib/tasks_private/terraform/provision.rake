require "json"
require 'yaml'
require 'logger'
require 'ruby-terraform'

namespace :provision do
  @testname = "provision-vm"
  @current_dir = ENV['cwd'] || Dir.pwd
  @terraform_dir = __dir__

  desc "check terraform is installed"
  task :check => :environment do
    system("command -v terraform > /dev/null") or raise("install terraform to provision powervc vm")
  end

  desc "provision a vm"
  task :apply => :check do
    config = setup
    plan(config)
    apply
  end

  desc "delete a vm"
  task :destroy => :check do
    config = setup
    destroy(config)
  end

  desc "snapshot a vm"
  task :snapshot => :apply do
    config = setup
    snapshot(config)
  end

  def setup
    Dir.chdir(@terraform_dir)

    log_file = Logger::LogDevice.new('ruby_terraform.log')
    stdout_device = Logger::LogDevice.new($stdout)
    multi_io = RubyTerraform::MultiIO.new(log_file, stdout_device)
    logger = Logger.new(multi_io)

    RubyTerraform.configure do |tconfig|
      tconfig.logger = logger
      tconfig.stdout = multi_io
      tconfig.stderr = multi_io
    end
    RubyTerraform.init

    secrets = YAML.safe_load(File.read(File.join(@current_dir, "config/secrets.yml")), :aliases => true)
    settings = YAML.safe_load(File.read(File.join(@current_dir, "config/powervs_testsettings.yml")), :aliases => true)

    setting = settings["test"].find { |key| key["testname"] == @testname }
    {:secret => secrets["test"]["ibm_cloud_power"], :setting => setting}
  end

  def plan(config)
    RubyTerraform.plan(
      :out          => 'terraform.tfplan',
      :auto_approve => true,
      :vars         => {
        :ibmcloud_api_key    => config[:secret]["api_key"],
        :power_instance_id   => config[:secret]["cloud_instance_id"],
        :ibmcloud_region     => config[:secret]["ibmcloud_region"],
        :vm_name             => config[:setting]["vm_name"],
        :volume_name         => config[:setting]["volume_name"],
        :key_pair_name       => config[:setting]["key_pair_name"],
        :image_name          => config[:setting]["image_name"],
        :sys_type            => config[:setting]["sys_type"],
        :public_network_name => config[:setting]["public_network_name"],
        :power_network_name  => config[:setting]["power_network_name"]
      }
    )
  end

  def apply
    RubyTerraform.apply(
      :plan         => 'terraform.tfplan',
      :auto_approve => true
    )
    jfile = File.open(File.join(@terraform_dir, "terraform.tfstate"))
    data = YAML.dump(JSON.parse(jfile.read))

    # NOTE: YAML dump adds trailing spaces, so removing them...
    data = data.split("\n").map(&:rstrip).join("\n")
    outfile = File.join(@current_dir, "spec/models/manageiq/providers/ibm_cloud/power_virtual_servers/cloud_manager/", "#{@testname}.yml")
    File.write(outfile, data)
  end

  def destroy(config)
    RubyTerraform.destroy(
      :chdir        => 'snapshot',
      :auto_approve => true,
      :vars         => {
        :ibmcloud_api_key  => config[:secret]["api_key"],
        :power_instance_id => config[:secret]["cloud_instance_id"],
        :ibmcloud_region   => config[:secret]["ibmcloud_region"],
        :vm_name           => config[:setting]["vm_name"],
      }
    )
    RubyTerraform.destroy(
      :auto_approve => true,
      :vars         => {
        :ibmcloud_api_key    => config[:secret]["api_key"],
        :power_instance_id   => config[:secret]["cloud_instance_id"],
        :ibmcloud_region     => config[:secret]["ibmcloud_region"],
        :vm_name             => config[:setting]["vm_name"],
        :volume_name         => config[:setting]["volume_name"],
        :key_pair_name       => config[:setting]["key_pair_name"],
        :image_name          => config[:setting]["image_name"],
        :sys_type            => config[:setting]["sys_type"],
        :public_network_name => config[:setting]["public_network_name"],
        :power_network_name  => config[:setting]["power_network_name"]
      }
    )
  end

  def snapshot(config)
    RubyTerraform.init(
      :chdir => 'snapshot'
    )
    RubyTerraform.plan(
      :chdir => 'snapshot',
      :out   => 'terraform.tfplan',
      :vars  => {
        :ibmcloud_api_key  => config[:secret]["api_key"],
        :power_instance_id => config[:secret]["cloud_instance_id"],
        :ibmcloud_region   => config[:secret]["ibmcloud_region"],
        :vm_name           => config[:setting]["vm_name"],
      }
    )
    RubyTerraform.apply(
      :chdir        => 'snapshot',
      :plan         => 'terraform.tfplan',
      :auto_approve => true
    )
  end
end
