class ManageIQ::Providers::IbmCloud::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :PowerVirtualServers
  require_nested :VPC

  private

  def all(api_client, list_method, args, collection_key = nil, opts = {})
    return enum_for(:all, api_client, list_method, args, collection_key, opts) unless block_given?

    collection_key ||= list_method.to_s.sub("list_", "")
    result = api_client.send(list_method, *args, opts)

    result.send(collection_key)&.each { |i| yield i }

    next_link = result._next&.href if result.respond_to?(:_next)
    return unless next_link

    start = parse_next_link(next_link)["start"]&.first
    all(api_client, list_method, args, collection_key, opts.merge(:start => start))
  end

  def parse_next_link(next_link)
    CGI.parse(URI(next_link).query)
  end
end
