# frozen_string_literal: true

# Methods to create a new json payload.
module ManageIQ::Providers::IbmCloud::VPC::CloudManager::Provision::Payload
  # Get a MiqTemplate instance for the template selected during provision.
  # @return [MiqTemplate]
  def vm_image
    @vm_image ||= MiqTemplate.find_by(:id => get_option(:src_vm_id))
  end

  # Create the hash that will be sent to the provider for provisioning.
  # @return [Hash] A complete hash for provisioning.
  def prepare_for_clone_task
    logger(__method__).debug("Final IBM VPC provision workflow form options. #{options}")
    payload = {
      :name                      => get_option(:vm_target_name),
      :keys                      => [{:id => get_option(:guest_access_key_pair)}],
      :profile                   => {:name => get_option_last(:instance_type)},
      :image                     => {:id => vm_image[:ems_ref]},
      :zone                      => {:name => get_option_last(:placement_availability_zone)},
      :vpc                       => {:id => get_option(:cloud_network)},
      :primary_network_interface => {
        :name            => 'eth0',
        :subnet          => {:id => get_option(:cloud_subnet)},
        :security_groups => security_groups.map { |sg| {:id => sg.ems_ref} }
      },
      :volume_attachments        => cloud_volumes,
      :boot_volume_attachment    => {
        :volume => {
          :name    => "#{get_option(:vm_target_name)}-boot",
          :profile => {:name => get_option_last(:storage_type)}
        }
      }
    }
    resource_group(payload)
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Add a resource group if it is selected. If not selected then VPC will use the default resource_group.
  # @param payload [Hash] Payload for provision.
  # @return [Hash] Payload for provision with optional resource_group set.
  def resource_group(payload)
    resource_group = get_option(:resource_group)
    payload[:resource_group] = {:id => resource_group} unless resource_group.nil?
    payload
  end

  # Create list of new and existing volumes to attach.
  # @return [Array<Hash>]
  def cloud_volumes
    volume_list = existing_volumes
    new_volumes = new_cloud_volumes
    logger(__method__).debug("IBM VPC provision requested #{volume_list.length} existing volumes and #{new_volumes.length} new volumes.")
    new_volumes + volume_list
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Create a list of existing volumes to attach.
  # @return [Array<Hash>]
  def existing_volumes
    cloud_volumes = options[:cloud_volumes] || []

    volume_list = []
    cloud_volumes.compact.each { |ems_ref| volume_list.append({:volume => {:id => ems_ref}}) }
    volume_list
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Create a list of new volumes to create and attach.
  # @return [Array<Hash>]
  def new_cloud_volumes
    new_volumes = options[:new_volumes] || []

    volume_list = []
    new_volumes.each { |volume| volume_list.append(new_cloud_volume(volume)) }
    volume_list
  rescue => e
    logger(__method__).log_backtrace(e)
  end

  # Create a hash for a new volume.
  # @param volume [Hash<Symbol => String, Integer>] A new_volume hash.
  # @return [Hash]
  def new_cloud_volume(volume)
    volume_on_instance_delete = volume[:volume_on_instance_delete] == 'on' # 'on' is the value returned by the checkbox.
    volume_profile = volume[:volume_profile] || get_option_last(:storage_type)

    {
      :delete_volume_on_instance_delete => volume_on_instance_delete,
      :volume                           => {
        :profile  => {:name => volume_profile},
        :name     => volume[:volume_name],
        :capacity => volume[:volume_size]
      }
    }
  rescue => e
    logger(__method__).log_backtrace(e)
  end
end
