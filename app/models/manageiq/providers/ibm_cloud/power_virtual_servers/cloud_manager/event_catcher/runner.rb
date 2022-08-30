class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    event_monitor_handle.stop
  end

  def monitor_events
    event_monitor_handle.start
    event_monitor_running
    event_monitor_handle.poll do |event|
      @queue.enq(event)
    end
  ensure
    stop_event_monitor
  end

  def queue_event(event)
    _log.info("#{log_prefix} Caught event [#{event[:eventID]}]")
    event_hash = ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::EventParser.event_to_hash(event, @cfg[:ems_id])
    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end

  private

  def event_monitor_handle
    @event_monitor_handle ||= self.class.module_parent::Stream.new(@ems)
  end
end
