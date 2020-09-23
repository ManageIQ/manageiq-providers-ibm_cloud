class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::SecurityGroup < ::SecurityGroup
  def self.display_name(number = 1)
    n_('Security Group (IBM)', 'Security Groups (IBM)', number)
  end
end
