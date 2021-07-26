class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImportDispatcher < ::Job::Dispatcher
  def dispatch
    jobs_by_ems, = Benchmark.realtime_block(:pending_import_jobs) { pending_import_jobs }

    jobs_by_ems.each do |ems_id, jobs|
      free = true # TODO: here determine if there is a free slot
      do_dispatch(job, ems_id) if free
    end
  end

  def pending_import_jobs
    pending_jobs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |job, h|
      h[job.options[:ems_id]] << job
    end
  end

  def do_dispatch(job, ems_id)
    MiqQueue.put_unless_exists(
      :args        => [:start],
      :class_name  => "Job",
      :instance_id => job.id,
      :method_name => "signal",
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => "smartstate",
      :task_id     => job.guid,
      :zone        => job.zone
    )
  end
end