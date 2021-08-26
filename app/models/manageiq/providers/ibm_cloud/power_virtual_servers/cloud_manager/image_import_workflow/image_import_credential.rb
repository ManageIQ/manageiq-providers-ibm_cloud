class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImageImportCredential < Ansible::Runner::Credential
  def self.auth_type
    'ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImageImportAuth'
  end

  def extra_vars
    {
      "encr_cos_creds" => auth.password,
    }
  end

  def env_vars
    {
      "CREDS_AES_IV"  => auth.auth_key_password,
      "CREDS_AES_KEY" => auth.auth_key,
    }
  end
end
