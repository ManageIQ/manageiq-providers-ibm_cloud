class ManageIQ::Providers::IbmCloud::VPC::NetworkManager::LoadBalancer < ::LoadBalancer
  def self.display_name(number = 1)
    n_('Load Balancer (IBM Cloud VPC)', 'Load Balancers (IBM Cloud VPC)', number)
  end
end
