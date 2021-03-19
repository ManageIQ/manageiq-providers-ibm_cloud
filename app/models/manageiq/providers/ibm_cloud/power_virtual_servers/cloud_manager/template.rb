class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  supports :provisioning do
    if ext_management_system
      unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning)) unless ext_management_system.supports?(:provisioning)
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  supports :import_image

  def provider_object(_connection = nil)
    ext_management_system.connect
  end

  def destroy
    delete_image
  end

  def delete_image_queue(userid)
    task_opts = {
      :action => "Deleting Cloud Image for user #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'delete_image',
      :instance_id => id,
      :role        => 'ems_operations',
      :queue_name  => ext_management_system.queue_name_for_ems_operations,
      :zone        => ext_management_system.my_zone,
      :args        => []
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def delete_image
    raw_delete_image
  end

  def raw_delete_image
    with_provider_connection(:service => "PCloudImagesApi") do |api|
      _log.info("Deleting cloud image=[name: '#{name}', id: '#{ems_ref}']")
      api.pcloud_cloudinstances_images_delete(ext_management_system.uid_ems, ems_ref)
    end
  rescue => e
    _log.error("image=[#{name}], error: #{e}")
  end

  def self.encrypt_with_aes(creds)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.encrypt

    key  = Base64.strict_encode64(cipher.random_key)
    iv   = Base64.strict_encode64(cipher.random_iv)
    encr = Base64.strict_encode64(cipher.update(creds.to_json) + cipher.final)

    [encr, key, iv]
  end

  def self.miq_img_by_ids(provider_id, id)
    powervc = ExtManagementSystem.find(provider_id)
    powervc.get_image_info(id)
  end

  def self.cos_creds(id)
    cos  = ExtManagementSystem.find(id)
    return cos.cos_creds
  end

  def self.node_creds(id)
    powervc  = ExtManagementSystem.find(id)
    endp = powervc.node_endpoint
    auth = powervc.node_auth

    return endp.hostname, auth.userid, auth.password
  end

  def self.image_ems_ref(bucket_id)
    MiqTemplate.find(bucket_id).uid_ems
  end

  def self.bucket_name(bucket_id)
    CloudObjectStoreContainer.find(bucket_id).name
  end

  def self.raw_import_image(ext_management_system, options = {})
    session_id = DateTime.now.strftime('%Q')

    location, user, password = node_creds(options['src_provider_id'])
    hosts = ["[powervc]\n#{location}\n[powervc:vars]\nansible_connection=ssh\nansible_user=#{user}\nansible_ssh_pass=#{password}"]

    cos_credentials = cos_creds(options['obj_storage_id'])
    bucket = bucket_name(options['bucket_id'])

    cos_ans_creds = {resource_instance_id: cos_credentials[0], apikey: cos_credentials[1], bucket_name: bucket, url_endpoint: cos_credentials[3]}
    cos_pvs_creds = {region: cos_credentials[2], bucketName: bucket, accessKey: cos_credentials[4], secretKey: cos_credentials[5]}

    encr_cos_creds, encr_cos_key, encr_cos_iv  = encrypt_with_aes(cos_ans_creds)

    extra_vars = {
      session_id:     session_id,
      provider_id:    options['src_provider_id'],
      image_id:       image_ems_ref(options['src_image_id']),
      credentials:    encr_cos_creds,
      creds_aes_key:  encr_cos_key,
      creds_aes_iv:   encr_cos_iv
    }

    options = {
      keep_ova:       options['keep_ova'],
      session_id:     session_id,
      ems_id:         ext_management_system.id,
      cos_id:         options['obj_storage_id'],
      bucket_name:    bucket,
      miq_img:        miq_img_by_ids(options['src_provider_id'], options['src_image_id']),
      cos_pvs_creds:  cos_pvs_creds,
      playbook_path:  ManageIQ::Providers::IbmCloud::Engine.root.join("content/ansible_runner/import.yaml"),
    }

    _log.info("execute image import playbook")
    job = ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow.create_job({}, extra_vars, options, hosts, credentials = [], poll_interval: 5.seconds)
    job.signal(:start)
  end

  def validate_delete_image
    validate_unsupported(_("Delete Cloud Template Operation"))
  end
end
