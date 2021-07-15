class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow < ManageIQ::Providers::AnsiblePlaybookWorkflow
  def load_transitions
    super.merge(:post_execute => {'running' => 'post_execute_poll'}, :post_execute_poll => {'post_execute_poll' => 'post_execute_poll'})
  end

  def post_execute
    ems = ExtManagementSystem.find(options[:ems_id])

    body = {
      :source        => 'url',
      :imageName     => options[:miq_img][:name],
      :osType        => options[:miq_img][:os],
      :diskType      => options[:diskType],
      :imageFilename => "#{options[:session_id]}.ova",
      **options[:cos_pvs_creds]
    }

    ems.with_provider_connection(:service => 'PCloudImagesApi') do |api|
      response = api.pcloud_cloudinstances_images_post(ems.uid_ems, body, {})
      context[:task_id] = response.taskref.task_id

      started_on = Time.now.utc
      update!(:context => context, :started_on => started_on)
      miq_task.update!(:started_on => started_on)
    end

    cleanup_git_repository

    queue_signal(:post_execute_poll, 'importing image into PVS', 'running')
  end

  def post_execute_poll(*args)
    msg, status = args
    set_status(msg, status)

    ems = ExtManagementSystem.find(options[:ems_id])

    msg    = nil
    status = nil
    signal = nil

    ems.with_provider_connection(:service => 'PCloudTasksApi') do |api|
      response = api.pcloud_tasks_get(context[:task_id])

      case response.status
      when 'capturing', 'downloading', 'creating', 'deleting', 'compressing', 'loading', 'started', 'uploading'
        signal = :post_execute_poll
        msg = 'importing image into PVS, current state is: ' + response.status
        status = 'running'
      when 'completed'
        signal = :finish
        msg = 'importing image into PVS has completed'
        status = 'ok'
      when 'failed'
        signal = :error
        msg = 'importing image into PVS has failed'
        status = 'error'
      else
        signal = :error
        msg = 'PVS API has responded with a non-standard status for a cloud-task: ' + response.status
        status = 'error'
        _log.warn(msg)
      end
    end

    queue_signal(signal, msg, status)
  end

  def post_poll_cleanup
    return if options[:keep_ova] == true

    cos = ExtManagementSystem.find(options[:cos_id])
    cos.remove_object(options[:bucket_name], options[:session_id] + '.ova')
  end

  def finish(*args)
    super(*args)
    post_poll_cleanup
  end

  def error(*args)
    super(*args)
    post_poll_cleanup
  end

  def cancel(*args)
    super(*args)

    # TODO: should we remove the image here if already importing?
    post_poll_cleanup
  end

  def abort_job(*args)
    super(*args)

    # TODO: should we remove the image here if already importing?
    post_poll_cleanup
  end
end
