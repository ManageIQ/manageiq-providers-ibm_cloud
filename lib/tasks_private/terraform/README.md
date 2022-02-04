### IBM Power System Virtual Server Test Framework

Topics

1. Test framework
2. Test configuration
3. Test run

#
### Test famework
This test will provision a simple AIX installed PowerVS VSI attached to two subnets, and a data volume using terraform script. The following version of terraform was used for development and testing.
> ```terraform --version
> Terraform v1.1.4
> on linux_amd64
> + provider registry.terraform.io/hashicorp/random v2.3.1
> + provider registry.terraform.io/ibm-cloud/ibm v1.38.0
> ```

User can install appropriate terraform package for their system by downloading it from [HashiCorm Learn](https://learn.hashicorp.com/tutorials/terraform/install-cli) site.

Terraform itself was invoked from a rake program using RubyTerraform, a ruby gem which is a simple wrapper which allows terraform execution with in a rakefile.
> ``` gem info ruby-terraform
> 
> *** LOCAL GEMS ***
> 
> ruby-terraform (1.3.1)
>     Author: InfraBlocks Maintainers
>     Homepage: https://github.com/infrablocks/ruby_terraform
>     License: MIT
>     Installed at: /usr/local/rvm/gems/ruby-2.7.3
> 
>     A simple Ruby wrapper for invoking Terraform commands.
> ```

The test generates a state yaml file :
> `./spec/models/manageiq/providers/ibm_cloud/power_virtual_servers/cloud_manager/<testname>.yml` 
where testname is the title of the test as defined in `*powervs_testsettings.yml*`. 

which gives the current state and configuration of the managed virtual server instance.

The rspec test file 
> `./spec/models/manageiq/providers/ibm_cloud/power_virtual_servers/cloud_manager/refresher.rb` 

contains various unit test including test for Virtual Server, network and data volume where the test results are compared by the provisoned server attributes stored in the `<testname>.yml` file.

#
### Test Configuraton
While the *config/secrets.yml* file stores the api_key along with the powervs service instance and region information, the test settings are stored in *config/powervs_testsettings.yml* as shown below

```
---
# secrets.yml file
test:
  ibm_cloud_power_syd04: &active
    api_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    power_instance_id: 749e3492-1ff4-4d45-b43c-513674930661
    sys_type: s922
    ibmcloud_region: syd
  ibm_cloud_power_mon01:
    api_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    power_instance_id: 8fa27c40-827c-4568-8813-79b398e9cd27
    ibmcloud_region: mon01
  ibm_cloud_power:
    <<: *active
```

```
---
# powervs_testsettings.yml
test:
  - testname: provision-vm
    vm_name: rdr-miq-test
    key_pair_name: miq-pvs
    public_network_name: public-192_168_165_88-29-VLAN_2039
    power_network_name: miq-net
    image_name: '7100-05-05'
    sys_type: s922
```

The terraform state is stored in the  


and helps define the PowerVS service instance, and the region code; vm name, and vm type; ssh public key; management and 
 network; cloud voulme name. These are used by ruby-terraform script to provision the test machine and rspec to test.


#
### Test run

Listing all the rake tests shows:
> ```
> rake provision:apply        # provision a vm
> rake provision:check        # check terraform is installed
> rake provision:destroy      # delete a vm
> rake app:spec               # Run all specs in spec directory (excluding plugin specs)
```

