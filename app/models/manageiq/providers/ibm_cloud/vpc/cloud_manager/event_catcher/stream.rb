class ManageIQ::Providers::IbmCloud::VPC::CloudManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @from = Time.now.to_i.to_s
    @poll_sleep = options[:poll_sleep] || 20.seconds
  end

  def start
    @stop_polling = false
    @from = Time.now.to_i.to_s
  end

  def stop
    @stop_polling = true
  end

  def poll
    loop do
      @to = Time.now.to_i.to_s

      ems.with_provider_connection(:service => 'events') do |api|
        events_client = api.sdk_client
        events = events_client.exportv2(:from => @from, :to => @to, :hosts => "is").result["lines"]
        @from = @to

        break if stop_polling

        events.each { |event| yield event}
      end
      sleep(poll_sleep)
    end
  end
end
