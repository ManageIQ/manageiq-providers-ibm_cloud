# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/ibm_cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-ibm_cloud"
  spec.version       = ManageIQ::Providers::IbmCloud::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ plugin for the IBM Cloud provider."
  spec.description   = "ManageIQ plugin for the IBM Cloud provider."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-ibm_cloud"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ibm_cloud_iam", "~> 1.0"
  spec.add_dependency "ibm_cloud_power", "~> 1.1", ">= 1.1.1"
  spec.add_dependency "ibm_cloud_resource_controller", "~> 2.0"
  spec.add_dependency "ibm-cloud-sdk", "~> 0.1"
  spec.add_dependency "ibm_cloud_activity_tracker", "~> 0.1"
  spec.add_dependency "ibm_cloud_databases", "~> 0.1"
  spec.add_dependency "ibm_cloud_global_tagging", "~> 0.1"
  spec.add_dependency "ibm_vpc", "~> 0.1"
  spec.add_dependency "prometheus-api-client", "~> 0.6"
  spec.add_dependency "rest-client", "~> 2.1"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov"
end
