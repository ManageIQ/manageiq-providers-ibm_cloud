class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImportDispatcher < ::Job::Dispatcher

  def dispatch
    pending, = Benchmark.realtime_block(:pending_import_jobs) { pending_import_jobs }
    running, = Benchmark.realtime_block(:running_import_jobs) { running_import_jobs }
    busy_src_ids = running.map { |_, dst| dst.map { |job| job[:options][:src_provider_id] } }.flatten

    pending.each do |dst_id, pending_jobs|
      return if running[dst_id].present?
      job = pending_jobs.detect { |x| busy_src_ids.exclude?(x[:options][:src_provider_id]) }
      busy_src_ids << job[:options][:src_provider_id]
      do_dispatch(job) unless job.nil?
    end
  end

  def running_import_jobs
    running_jobs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |job, h|
      h[job.options[:ems_id]] << job
    end
  end

  def pending_import_jobs
    pending_jobs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |job, h|
      h[job.options[:ems_id]] << job
    end
  end

  def do_dispatch(job)
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