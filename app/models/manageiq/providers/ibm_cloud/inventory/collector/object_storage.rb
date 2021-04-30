class ManageIQ::Providers::IbmCloud::Inventory::Collector::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Collector
  require_nested :ObjectManager

  def buckets
    buckets = []

    # XXX: filtering out buckets not from our region, as of now the REST call fails with an
    # exception if used with from different region than the bucket's
    (connection.list_buckets[:buckets] || []).each do |bucket|
      connection.get_bucket_location(:bucket => bucket[:name]).location_constraint
      buckets << bucket
    rescue
      _log.warn("bucket '#{bucket[:name]}' is not from our region '#{manager.provider_region}', skipping")
    end

    buckets
  end

  def objects(bucket_id, token = nil)
    params = token.nil? ? {:continuation_token => token} : {}
    connection.list_objects_v2({:bucket => bucket_id}, params)
  end

  private

  def connection
    @connection ||= manager.connect
  end
end
