# coding: utf-8

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/ibm_cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-ibm_cloud"
  spec.version       = ManageIQ::Providers::IbmCloud::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Ibm Cloud plugin for ManageIQ"
  spec.description   = "Ibm Cloud plugin for ManageIQ"
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-ibm_cloud"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ibm-cloud-sdk", "~> 0.1"
  spec.add_development_dependency "simplecov"
end
