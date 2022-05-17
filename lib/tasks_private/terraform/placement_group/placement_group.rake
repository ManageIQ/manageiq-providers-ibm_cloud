require_relative "../common"

namespace :placement_group do
  @testname = "placement_group"

  desc "check terraform is installed"
  task :check => :environment do
    system("command -v terraform > /dev/null") or raise("install terraform to provision powervc vm")
  end

  desc "provision a vm in placement group"
  task :apply => :check do
    @testname = "placement_group"
    config = setup
    plan(config)
    apply
  end

  desc "delete a vm"
  task :destroy => :check do
    @testname = "placement_group"
    config = setup
    destroy(config)
  end
end
