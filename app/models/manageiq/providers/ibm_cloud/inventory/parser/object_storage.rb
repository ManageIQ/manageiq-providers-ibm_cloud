class ManageIQ::Providers::IbmCloud::Inventory::Parser::ObjectStorage < ManageIQ::Providers::IbmCloud::Inventory::Parser
  require_nested :ObjectManager

  BUCKET_TAB_LIMIT = 2000

  def parse
    buckets
  end

  private

  def buckets
    collector.buckets.each do |bucket|
      bucket_id = bucket['name']
      total_size, total_count = process_bucket(bucket_id)

      persister.cloud_object_store_containers.build(
        :ems_ref => bucket_id,
        :key     => bucket_id,
        :bytes   => total_size,
        :object_count => total_count,
      )
    end
  end

  def process_bucket(bucket_id)
    total_size = total_count = 0

    BUCKET_TAB_LIMIT.times do
      objects = collector.objects(bucket_id)
      token = objects[:continuation_token]

      (objects[:contents] || []).each do |object|
        total_size += object[:size]
        total_count += 1

        persister.cloud_object_store_objects.build(
          :ems_ref                      => "#{bucket_id}_#{object['key']}",
          :etag                         => object['etag'],
          :last_modified                => object['last_modified'],
          :content_length               => object['size'],
          :key                          => object['key'],
          :cloud_object_store_container => persister.cloud_object_store_containers.lazy_find(bucket_id),
        )
      end

      break if token.blank?
    end

    return total_size, total_count
  end
end