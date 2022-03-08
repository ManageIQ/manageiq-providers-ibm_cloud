class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::AuthKeyPair < ManageIQ::Providers::CloudManager::AuthKeyPair
  supports :create
  supports :delete

  def self.raw_create_key_pair(ext_management_system, create_options)
    require "sshkey"
    ext_management_system.with_provider_connection(:service => "PCloudTenantsSSHKeysApi") do |api|
      tenant_id = ext_management_system.pcloud_tenant_id(api.api_client)
      ssh_key   = IbmCloudPower::SSHKey.new(
        :name    => create_options['name'],
        :ssh_key => create_options['public_key']
      )

      api.pcloud_tenants_sshkeys_post(tenant_id, ssh_key)
      {
        :name        => create_options['name'],
        :public_key  => create_options['public_key'],
        :fingerprint => SSHKey.sha1_fingerprint(create_options['public_key'])
      }
    end
  rescue => err
    _log.error("keypair=[#{create_options[:name]}], error: #{err}")
    _log.log_backtrace(err)
    raise MiqException::Error, err.to_s, err.backtrace
  end

  def raw_delete_key_pair
    resource.with_provider_connection(:service => "PCloudTenantsSSHKeysApi") do |api|
      api.pcloud_tenants_sshkeys_delete(resource.tenant_id, name)
    end
  rescue => err
    _log.log_backtrace(err)
    _log.error("keypair=[#{name}], error: #{err}")
    raise MiqException::Error, err.to_s, err.backtrace
  end
end
