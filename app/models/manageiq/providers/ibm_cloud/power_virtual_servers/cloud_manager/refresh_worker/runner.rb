class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::RefreshWorker::Runner < ManageIQ::Providers::BaseManager::RefreshWorker::Runner
  def do_before_work_loop
    @emss.select { |ems| ems.kind_of?(EmsCloud) }.each do |ems|
      log_prefix = "EMS [#{ems.hostname}] as [#{ems.authentication_userid}]"
      _log.info("#{log_prefix} Queueing initial refresh for EMS #{ems.id}.")
      EmsRefresh.queue_refresh(ems)
    end
  end
end
