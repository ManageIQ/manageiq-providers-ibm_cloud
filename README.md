# ManageIQ::Providers::IbmCloud

[![CI](https://github.com/ManageIQ/manageiq-providers-ibm_cloud/actions/workflows/ci.yaml/badge.svg?branch=petrosian)](https://github.com/ManageIQ/manageiq-providers-ibm_cloud/actions/workflows/ci.yaml)
[![Maintainability](https://api.codeclimate.com/v1/badges/41e71ad240a79b0be9d9/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-providers-ibm_cloud/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/41e71ad240a79b0be9d9/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-providers-ibm_cloud/test_coverage)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq-providers-ibm_cloud?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build history for petrosian branch](https://buildstats.info/github/chart/ManageIQ/manageiq-providers-ibm_cloud?branch=petrosian&buildCount=50&includeBuildsFromPullRequest=false&showstats=false)](https://github.com/ManageIQ/manageiq-providers-ibm_cloud/actions?query=branch%3Amaster)

ManageIQ plugin for the IBM Cloud provider

## Implementations

This provider is structured to encompass manager implementations for multiple
IBM Cloud offerings:

### IBM Power Systems Virtual Servers

This ManageIQ provider allows users to manage their IBM Power Systems Virtual
Servers cloud landscape, seamlessly integrating it with the rest of their
hybrid multicloud infrastructure.

As some background, IBM Power Systems Virtual Servers is a Power Systems
infrastructure as a service (IaaS) offering with connectivity to the catalog
of IBM Cloud Services that you can use to deploy a virtual server, also known
as a logical partition (LPAR), in a matter of minutes. IBM Power Systems
clients who have typically relied upon on-premises-only infrastructure can now
quickly and economically extend their Power IT resources off-premises.

This ManageIQ provider supports the following IBM Power Systems Virtual Servers
high level operations:

- Resource discovery and inventory
- Operational control for VMs, storage volumes and networks
- SSH key management

## Development

See the section on plugins in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup/plugins)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the *spec* directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
