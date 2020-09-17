class ManageIQ::Providers::IbmCloud::Inventory::Parser::VPC < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :CloudManager

  attr_reader :img_to_os

  def initialize
    @img_to_os = {}
  end

  def parse
    images
    instances
  end

  def images
    collector.images.each do |image|
      img_to_os[image[:id]] = image&.dig(:operating_system, :name)
      persister.miq_templates.build(
        :uid_ems            => image[:id],
        :ems_ref            => image[:id],
        :name               => image[:name],
        :description        => image&.dig(:operating_system, :display_name),
        :location           => collector.manager.provider_region,
        :vendor             => "ibm",
        :connection_state   => "connected",
        :raw_power_state    => "never",
        :template           => true,
        :publicly_available => true
      )
    end
  end

  def instances
    collector.vms.each do |instance|
      persister_instance = persister.vms.build(
        :description      => "IBM Cloud Server",
        :ems_ref          => instance[:id],
        :location         => instance&.dig(:zone, :name),
        :genealogy_parent => persister.miq_templates.lazy_find(instance&.dig(:image, :id)),
        :name             => instance[:name],
        :vendor           => "ibm",
        :connection_state => "connected",
        :raw_power_state  => instance[:status],
        :uid_ems          => instance[:id]
      )

      instance_hardware(persister_instance, instance)
      instance_operating_system(persister_instance, instance)
    end
  end

  def instance_hardware(persister_instance, instance)
    persister.hardwares.build(
      :vm_or_template  => persister_instance,
      :cpu_sockets     => Float(instance&.dig(:vcpu, :count)).ceil,
      :cpu_total_cores => Float(instance&.dig(:vcpu, :count)).ceil,
      :memory_mb       => Integer(instance[:memory]) * 1024
    )
  end

  def instance_operating_system(persister_instance, instance)
    image_id = instance&.dig(:image, :id)
    os = img_to_os[image_id] || pub_img_os(image_id)
    persister.operating_systems.build(
      :vm_or_template => persister_instance,
      :product_name   => os
    )
  end

  def pub_img_os(image_id)
    collector.image(image_id)&.dig(:operating_system, :name)
  end
end
