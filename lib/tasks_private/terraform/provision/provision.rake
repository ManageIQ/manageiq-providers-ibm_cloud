require_relative "../common"

namespace :provision do
  @testname = "provision"

  desc "check terraform is installed"
  task :check => :environment do
    system("command -v terraform > /dev/null") or raise("install terraform to provision powervc vm")
  end

  desc "provision a vm"
  task :apply => :check do
    @testname = "provision"
    config = setup
    plan(config)
    apply
  end

  desc "delete a vm"
  task :destroy => :check do
    @testname = "provision"
    config = setup
    destroy(config)
  end
end
