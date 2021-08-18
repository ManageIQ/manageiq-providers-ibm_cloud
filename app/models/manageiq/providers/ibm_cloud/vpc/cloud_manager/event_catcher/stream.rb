class ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @from = Time.now.to_i
    @poll_sleep = options[:poll_sleep] || 20.seconds
  end

  def start
    @stop_polling = false
    @from = Time.now.to_i
  end

  def stop
    @stop_polling = true
  end

  def poll
    loop do
      @to = Time.now.to_i

      ems.with_provider_connection(:service => 'events') do |api|
        events_client = api.sdk_client

        # IBM Cloud Activity Tracker has a delay from the time that
        # an event is fired to when it is available to be retrieved by the API.
        # Therefore a 30-second timestamp offset is used to allow
        # events to persist on the service and get retrieved.
        events = events_client.exportv2(:from => (@from - 30).to_s, :to => (@to - 30).to_s, :hosts => "is")
                              .result["lines"]

        @from = @to

        break if stop_polling

        events.each { |event| yield event }
      end
      sleep(poll_sleep)
    end
  end
end
