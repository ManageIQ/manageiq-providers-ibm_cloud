require_relative "../common"

namespace :snapshot do
  @testname = "snapshot"

  desc "check terraform is installed"
  task :check => :environment do
    system("command -v terraform > /dev/null") or raise("install terraform to provision powervc vm")
  end

  desc "snapshot a vm"
  task :apply => :check do
    @testname = "snapshot"
    config = setup
    snapshot(config)
    apply
  end

  def snapshot(config)
    @testname = "snapshot"
    Dir.chdir(@test_dir)

    RubyTerraform.plan(
      :out          => 'terraform.tfplan',
      :auto_approve => true,
      :vars         => {
        :ibmcloud_api_key  => config[:secret]["api_key"],
        :power_instance_id => config[:secret]["cloud_instance_id"],
        :ibmcloud_region   => config[:secret]["ibmcloud_region"],
        :volume_name       => config[:setting]["volume_name"],
        :vm_name           => config[:setting]["vm_name"]
      }
    )
  end
end
