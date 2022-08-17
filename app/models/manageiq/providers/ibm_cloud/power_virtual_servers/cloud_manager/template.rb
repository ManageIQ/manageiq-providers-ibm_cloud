class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  extend ActiveSupport::Concern

  supports :import_image

  supports :provisioning do
    if ext_management_system
      unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning)) unless ext_management_system.supports?(:provisioning)
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  def image?
    true
  end

  def snapshot?
    false
  end

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

  def self.raw_import_image(ext_management_system, options = {})
    session_id = SecureRandom.uuid
    wrkfl_timeout = options['timeout'].to_i.hours

    cos = ExtManagementSystem.find(options['obj_storage_id'])
    raise MiqException::Error, _("unable to find cloud object storage by this id '#{options['obj_storage_id']}'") if cos.nil?

    location, node_auth, _ = node_creds(options['src_provider_id'])
    guid, apikey, region, endpoint, _, _ = cos.cos_creds
    bucket = bucket_name(options['bucket_id'])
    diskType = CloudVolumeType.find(options['disk_type_id']).name

    cos_data = {:cos_id => cos.id, :region => region, :bucketName => bucket}
    cos_ans_creds = {:resource_instance_id => guid, :apikey => apikey, :bucket_name => bucket, :url_endpoint => endpoint}
    encr_cos_creds, encr_cos_key, encr_cos_iv = encrypt_with_aes(cos_ans_creds)

    host = "[powervc]\n#{location}\n[powervc:vars]\nansible_connection=ssh\nansible_user=#{node_auth.userid}"

    # FIXME: setting this to PKey only authentication until a fix to the appearing of
    # FIXME: the password in Logs/DB is implemented
    node_auth.options = 'pkey'

    if node_auth.options == 'pkey'
      ssh_creds = set_ssh_pkey_auth(options['dst_provider_id'], node_auth.auth_key, node_auth.auth_key_password)
    else
      host = "#{host}\nansible_ssh_pass=#{node_auth.password}"
    end

    import_creds = set_import_auth(options['dst_provider_id'], encr_cos_key, encr_cos_iv, encr_cos_creds)
    credentials  = [import_creds, ssh_creds].compact

    # FIXME: fixing the value of the rcfile location until a secure way of
    # FIXME: env variable passing is implemented in the corresp. playbook
    rcfile = '/opt/ibm/powervc/powervcrc'

    extra_vars = {
      :session_id  => session_id,
      :provider_id => options['src_provider_id'],
      :image_id    => image_ems_ref(options['src_image_id']),
      :powervc_rc  => rcfile,
    }

    workflow_opts = {
      :keep_ova        => options['keep_ova'],
      :session_id      => session_id,
      :ems_id          => ext_management_system.id,
      :src_provider_id => options['src_provider_id'].to_i,
      :cos_id          => options['obj_storage_id'],
      :bucket_name     => bucket,
      :diskType        => diskType,
      :miq_img         => miq_img_by_ids(options['src_provider_id'], options['src_image_id']),
      :cos_data        => cos_data,
      :import_creds_id => import_creds,
      :ssh_creds_id    => ssh_creds,
      :playbook_path   => ManageIQ::Providers::IbmCloud::Engine.root.join("content/ansible_runner/run.yml"),
    }

    _log.info("execute image import playbook")
    ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow.create_job({}, extra_vars, workflow_opts, [host], credentials, :poll_interval => 5.seconds, :timeout => wrkfl_timeout)
  end

  private_class_method def self.set_import_auth(dst_provider_id, key, iv, encr_cos_creds)
    powervs = ExtManagementSystem.find(dst_provider_id)
    powervs.create_import_auth(key, iv, encr_cos_creds)
  end

  private_class_method def self.set_ssh_pkey_auth(dst_provider_id, pkey, unlock)
    powervs = ExtManagementSystem.find(dst_provider_id)
    powervs.create_ssh_pkey_auth(pkey, unlock)
  end

  private_class_method def self.encrypt_with_aes(creds)
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.encrypt

    key  = Base64.strict_encode64(cipher.random_key)
    iv   = Base64.strict_encode64(cipher.random_iv)
    encr = Base64.strict_encode64(cipher.update(creds.to_json) + cipher.final)

    [encr, key, iv]
  end

  private_class_method def self.miq_img_by_ids(provider_id, image_id)
    powervc = ExtManagementSystem.find(provider_id)
    powervc.get_image_info(image_id)
  end

  private_class_method def self.node_creds(provider_id)
    powervc = ExtManagementSystem.find(provider_id)
    node_endp = powervc.endpoint(:node)
    def_endp = powervc.endpoint(:default)
    auth = powervc.node_auth

    rcfile = node_endp&.options
    default_rcfile = '/opt/ibm/powervc/powervcrc'
    return def_endp.hostname, auth, rcfile.presence || default_rcfile
  end

  private_class_method def self.image_ems_ref(bucket_id)
    MiqTemplate.find(bucket_id).uid_ems
  end

  private_class_method def self.bucket_name(bucket_id)
    CloudObjectStoreContainer.find(bucket_id).name
  end
end
