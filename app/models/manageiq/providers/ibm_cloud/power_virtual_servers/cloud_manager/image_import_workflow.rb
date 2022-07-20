class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow < ManageIQ::Providers::ImageImportJob
  def load_transitions
    super.merge(
      :post_execute      => {'running' => 'post_execute_poll'},
      :post_execute_poll => {'post_execute_poll' => 'post_execute_poll'}
    )
  end

  def trunc_err_msg(error_msg)
    max_err_sz = 1024
    trunc_msg = '[TRUNCATED OUTPUT - see full description in the server logs];' if !error_msg.nil? && (error_msg.length > max_err_sz)
    "#{trunc_msg}#{error_msg&.truncate(max_err_sz)}"
  end

  def process_runner_result(result)
    context[:ansible_runner_return_code] = result.return_code
    context[:ansible_runner_stdout]      = result.parsed_stdout

    if result.return_code != 0
      fail_line = context[:ansible_runner_stdout].detect { |line| line['stdout'].include?("fatal:") }
      error_match = fail_line&.fetch('stdout')&.match(/"msg": "(.*)"/)
      error_dsc = "'#{error_match[1]}'" unless error_match.nil?

      message = "ansible playbook failed with the message: '#{trunc_err_msg(error_dsc)}'"
      signal = :abort
      status = 'error'
      _log.error("ansible playbook failed with the message: \n'#{result.parsed_stdout.join("\n")}'")
      queue_signal(signal, message, status)
    else
      message = 'ansible playbook completed, starting import from the cloud object storage'
      signal = :post_execute
      status = 'ok'
      set_status(message, status)
      queue_signal(signal)
    end
  end

  def start
    queue_signal(:pre_execute, :msg_timeout => options[:timeout])
  end

  def post_execute
    cleanup_git_repository

    ems = ExtManagementSystem.find_by(:id => options[:ems_id])
    raise MiqException::Error, _("unable to find ems by this id '#{options[:ems_id]}'") if ems.nil?

    cos_data = options[:cos_data]

    region = cos_data[:region]
    bucket_name = cos_data[:bucketName]

    cos = ExtManagementSystem.find_by(:id => cos_data[:cos_id])
    raise MiqException::Error, _("unable to find cloud object storage by this id '#{options['obj_storage_id']}'") if cos.nil?

    _, _, _, _, access_key, secret_key = cos.cos_creds

    body = {
      :imageName     => options[:miq_img][:name],
      :osType        => options[:miq_img][:os],
      :storageType   => options[:diskType],
      :imageFilename => "#{options[:session_id]}.ova",
      :region        => region,
      :bucketName    => bucket_name,
      :accessKey     => access_key,
      :secretKey     => secret_key,
    }

    message = nil
    signal = nil
    status = nil

    ems.with_provider_connection(:service => 'PCloudImagesApi') do |api|
      response = api.pcloud_v1_cloudinstances_cosimages_post(ems.uid_ems, body, {})
      context[:job_id] = response.id
      update!(:context => context)

      message = 'initiated OVA file importing from the cloud object storage'
      signal = :post_execute_poll
      status = 'ok'
    rescue => e
      message = "failed to initiate OVA file importing from the cloud object storage: '#{trunc_err_msg(e.message)}'"
      signal = :abort
      status = 'error'
      _log.error("OVA image import failure: '#{e.message}'")
    end

    set_status(message, status)
    queue_signal(signal, message, status)
  end

  def try_extract_api_error(api_e)
    JSON.parse(api_e.response_body)["description"] if api_e.response_body
  rescue JSON::ParserError => e
    _log.warn("unable to parse the error description as a JSON: '#{e.message}'")
  end

  def post_execute_poll(*_args)
    ems = ExtManagementSystem.find(options[:ems_id])
    max_retries = 10

    message = nil
    signal  = nil
    status  = nil
    deliver = nil

    ems.with_provider_connection(:service => 'PCloudJobsApi') do |api|
      begin
        response = api.pcloud_cloudinstances_jobs_get(ems.uid_ems, context[:job_id])
      rescue IbmCloudPower::ApiError => e
        retr = context[:retry].to_i
        raise "unable to get job status after #{max_retries} tries, see server logs" if retr >= max_retries

        context[:retry] = retr + 1

        error_dsc = trunc_err_msg(try_extract_api_error(e))
        message = "failed to retrieve cloud-job: '#{error_dsc}'; try #{retr + 1}/#{max_retries}"
        deliver = Time.now.utc + 1.minute
        signal = :post_execute_poll
        status = 'error'
        break
      end

      case response.status.state
      when 'running'
        context[:retry] = 0
        message = "importing image into PVS, state: '#{response.status.state}' progress: '#{response.status.progress}' message: '#{response.status.message}'"
        signal = :post_execute_poll
        status = 'ok'
      when 'completed'
        message = 'importing image into image registry has completed'
        signal = :finish
        status = 'ok'
      when 'failed'
        raise "importing into image registry failed: '#{trunc_err_msg(response.status)}'"
      else
        raise "incompatible API, unexpected status: '#{response.status}'"
      end
    rescue => e
      signal = :abort
      status = 'error'
      message = e.message
    ensure
      update!(:context => context)
      set_status(message, status)
      queue_signal(signal, message, status, :deliver_on => deliver)
    end
  end

  def post_poll_cleanup(*args)
    ems = ExtManagementSystem.find(options[:ems_id])
    ems.remove_import_auth(options[:import_creds_id])
    ems.remove_ssh_auth(options[:ssh_creds_id]) if options[:ssh_creds_id]
    return if options[:keep_ova] == true

    begin
      cos = ExtManagementSystem.find(options[:cos_id])
      cos.remove_object(options[:bucket_name], "#{options[:session_id]}.ova")
    rescue => e
      result = args[0]
      set_status("#{result}; cleanup result: cannot remove transient OVA image: #{trunc_err_msg(e.message)}", 'error')
      _log.error("#{result}; cleanup result: cannot remove transient OVA image: #{e.message}")
    end
  end

  def finish(*args)
    super(*args)
    post_poll_cleanup(*args)
  end

  def abort(*args)
    super(*args)
    # TODO: how to handle fatal error (roll-back changes)?
    post_poll_cleanup(*args)
  end

  def cancel(*args)
    super(*args)
    # TODO: how to handle user cancellation (roll-back changes)?
    post_poll_cleanup(*args)
  end
end
