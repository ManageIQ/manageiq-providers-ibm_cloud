class ManageIQ::Providers::IbmCloud::VPC::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::IbmCloud::VPC::ManagerMixin

  def image_name
    'ibm'
  end

  def self.hostname_required?
    false
  end

  def self.ems_type
    @ems_type ||= 'ibm_vpc'.freeze
  end

  def self.description
    @description ||= 'IBM Virtual Private Cloud'.freeze
  end
end
