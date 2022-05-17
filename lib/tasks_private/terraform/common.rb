require "json"
require 'yaml'
require 'logger'
require 'ruby-terraform'

def setup
  @current_dir = ENV['cwd'] || Dir.pwd
  @setting_dir = File.join(@current_dir, "lib/tasks_private/terraform")
  @test_dir = File.join(@current_dir, "lib/tasks_private/terraform/#{@testname}")
  Dir.chdir(@test_dir)

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
  settings = YAML.safe_load(File.read(File.join(@setting_dir, "powervs_testsettings.yml")), :aliases => true)

  setting = settings["test"].find { |key| key["testname"] == @testname }
  {:secret => secrets["test"]["ibm_cloud_power"], :setting => setting}
end

def plan(config)
  Dir.chdir(@test_dir)
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
  Dir.chdir(@test_dir)
  RubyTerraform.apply(
    :plan         => 'terraform.tfplan',
    :auto_approve => true
  )
  jfile = File.open(File.join(@test_dir, "terraform.tfstate"))
  data = YAML.dump(JSON.parse(jfile.read))

  # NOTE: YAML dump adds trailing spaces, so removing them...
  data = data.split("\n").map(&:rstrip).join("\n")
  outfile = File.join(@current_dir, "spec/models/manageiq/providers/ibm_cloud/power_virtual_servers/cloud_manager/", "#{@testname}.yml")
  File.write(outfile, data)
end

def destroy(config)
  Dir.chdir(@test_dir)
  RubyTerraform.destroy(
    :auto_approve => true,
    :vars         => {
      :ibmcloud_api_key    => config[:secret]["api_key"],
      :power_instance_id   => config[:secret]["power_instance_id"],
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
