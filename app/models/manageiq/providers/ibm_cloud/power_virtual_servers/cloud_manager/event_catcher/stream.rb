class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @poll_sleep = options[:poll_sleep] || 20.seconds
  end

  def start
    @stop_polling = false
  end

  def stop
    @stop_polling = true
  end

  def poll
    from_time = Time.now.utc.to_i

    pcloud_events_api = ems.connect(:service => "PCloudEventsApi")
    loop do
      begin
        events = pcloud_events_api.pcloud_events_getsince(@ems.uid_ems, from_time).events
      # TODO: Only rescue token experation exception
      rescue Exception => e
        pcloud_events_api = ems.connect(:service => "PCloudEventsApi")
      end
      from_time = Time.now.utc.to_i
      events.each { |event| yield event.to_hash }
      break if stop_polling
      sleep(poll_sleep)
    end
  end
end
