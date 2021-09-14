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

    loop do
      ems.with_provider_connection(:service => "PCloudEventsApi") do |api|
        # Could also use IBM Cloud Activity Tracker like the VPC provider
        events = api.pcloud_events_getsince(ems.uid_ems, from_time).events
        from_time = Time.now.utc.to_i

        break if stop_polling

        events.each { |event| yield event.to_hash }
      end

      sleep(poll_sleep)
    end
  end
end
