class ManageIQ::Providers::IbmCloud::Inventory::Collector::VPC < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager

  def collect
  end

  def vms
    all("instances")
  end

  def vm_key_pairs(vm_id)
    vpc.get_instance_initialization(:id => vm_id)&.result&.dig("keys") || []
  end

  def flavors
    vpc.list_instance_profiles&.result&.dig("profiles")
  end

  def images
    @images ||= images_by_id.values
  end

  def images_by_id
    @images_by_id ||= all("images").index_by { |image| image["id"] }
  end

  def image(image_id)
    vpc.get_image(:id => image_id)
  end

  def keys
    vpc.list_keys&.result&.dig("keys")
  end

  def availability_zones
    vpc.list_region_zones(:region_name => manager.provider_region)&.result&.dig("zones")
  end

  def security_groups
    all("security_groups")
  end

  def cloud_networks
    all("vpcs")
  end

  def cloud_subnets
    all("subnets")
  end

  def floating_ips
    all("floating_ips")
  end

  def tags(attached_to)
    global_tagging.list_tags(:attached_to => attached_to)&.result&.dig("items") || []
  end

  def volumes
    all("volumes")
  end

  def volume(volume_id)
    vpc.get_volume(:id => volume_id)&.result
  end

  private

  def api_key
    @api_key ||= manager.authentication_key
  end

  def token
    @token ||= manager.class.raw_connect(api_key)
  end

  def vpc
    @vpc ||= begin
      require "ibm_vpc"
      service_url = "https://#{manager.provider_region}.iaas.cloud.ibm.com/v1"
      IbmVpc::VpcV1.new(:version => "2020-08-01", :authenticator => token, :service_url => service_url)
    end
  end

  def global_tagging
    @global_tagging ||= begin
      require "ibm_cloud_global_tagging/global_tagging_v1"
      IbmCloudGlobalTagging::GlobalTaggingV1.new(:authenticator => token)
    end
  end

  def all(collection_name, list_method: nil)
    return enum_for(:all, collection_name, :list_method => list_method) unless block_given?

    start = nil
    list_method ||= "list_#{collection_name}"

    loop do
      response = vpc.send(list_method, :start => start)
      response.result[collection_name]&.each { |i| yield i }

      next_link = response.result.dig("next", "href")
      break if next_link.nil?

      start = parse_next_link(next_link)
    end
  end
end
