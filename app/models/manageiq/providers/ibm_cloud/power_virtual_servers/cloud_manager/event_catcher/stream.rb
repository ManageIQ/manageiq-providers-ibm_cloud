class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @poll_sleep = options[:poll_sleep] || 30.seconds
  end

  def start
    @stop_polling = false
  end

  def stop
    @stop_polling = true
  end

  def poll
    from_time = Time.now.utc.to_i

    loop do
      pcloud_events_api = ems.connect(:service => "PCloudEventsApi")

      retry_connection = true
      events = pcloud_events_api.pcloud_events_getsince(@ems.uid_ems, {:from_time=>from_time}).events

      from_time = Time.now.utc.to_i

      sleep(poll_sleep)

      events.each { |event| yield event.to_hash }
      break if stop_polling
    rescue IbmCloudPower::ApiError => e
      raise unless e.code == 403 && retry_connection

      retry_connection = false
      retry
    end
  end
end
