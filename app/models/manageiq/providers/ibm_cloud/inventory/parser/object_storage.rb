class ManageIQ::Providers::IbmCloud::Inventory::Parser::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :StorageManager

  BUCKET_TAB_LIMIT = 1000

  def parse
    buckets
  end

  private

  def buckets
    collector.buckets.each do |bucket|
      bucket_id = bucket['name']
      total_size = total_count = 0

      collector.objects(bucket_id) do |object|
        total_size += object[:size]
        total_count += 1

        persister.cloud_object_store_objects.build(
          :ems_ref                      => "#{bucket_id}_#{object['key']}",
          :etag                         => object['etag'],
          :last_modified                => object['last_modified'],
          :content_length               => object['size'],
          :key                          => object['key'],
          :cloud_object_store_container => persister.cloud_object_store_containers.lazy_find(bucket_id)
        )
      end

      persister.cloud_object_store_containers.build(
        :ems_ref      => bucket_id,
        :key          => bucket_id,
        :bytes        => total_size,
        :object_count => total_count
      )
    end
  end
end
