module ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Provision::StateMachine
  def create_destination
    signal :prepare_volumes
  end

  def prepare_volumes
    new_volumes = options[:new_volumes]
    phase_context[:new_volumes] = []

    if new_volumes.any?
      source.with_provider_object({:service => "PowerIaas"}) do |power_iaas|
        new_volumes.each do |new_volume|
          phase_context[:new_volumes] << power_iaas.create_volume(new_volume)['volumeID']
        end
      end
    end

    # TODO: find out if we have to wait here until cloud volumes are available

    signal :prepare_provision
  end

end