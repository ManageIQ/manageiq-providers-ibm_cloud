class ManageIQ::Providers::IbmCloud::Inventory::Collector::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :StorageManager

  BUCKET_TAB_LIMIT = 1000

  def buckets
    buckets = []

    # XXX: filtering out buckets not from our region, as of now the REST call fails with an
    # exception if used with from different region than the bucket's
    (connection.list_buckets[:buckets] || []).each do |bucket|
      connection.get_bucket_location(:bucket => bucket[:name]).location_constraint
      buckets << bucket
    rescue Aws::S3::Errors::NoSuchBucket
      _log.warn("bucket '#{bucket[:name]}' is not from our region '#{manager.provider_region}', skipping")
    end

    buckets
  end

  def objects(bucket_id)
    params = {}
    BUCKET_TAB_LIMIT.times do
      objects = connection.list_objects_v2({:bucket => bucket_id}, params)
      params = {:continuation_token => objects[:continuation_token]}
      objects[:contents].to_a.each { |content| yield content }

      break if params[:contiuation_token].nil?
    end
  end

  private

  def connection
    @connection ||= manager.connect
  end
end
