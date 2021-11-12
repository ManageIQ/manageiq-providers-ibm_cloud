class ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @from = Time.now.to_i
    @poll_sleep = options[:poll_sleep] || 20.seconds
    @service_key = ems.authentication_key("events")
  end

  def start
    @stop_polling = false
    @from = Time.now.to_i
  end

  def stop
    @stop_polling = true
  end

  def poll
    events_client = ems.connect.events(:region => ems.provider_region, :service_key => @service_key).sdk_client
    loop do
      @to = Time.now.to_i

      # IBM Cloud Activity Tracker has a delay from the time that
      # an event is fired to when it is available to be retrieved by the API.
      # Therefore a 30-second timestamp offset is used to allow
      # events to persist on the service and get retrieved.
      events = events_client.exportv2(:from => (@from - 30).to_s, :to => (@to - 30).to_s, :hosts => "is")
                            .result["lines"]

      @from = @to

      events.each { |event| yield event }

      break if stop_polling

      sleep(poll_sleep)
    end
  end
end
