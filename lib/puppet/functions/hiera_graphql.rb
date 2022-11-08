Puppet::Functions.create_function(:hiera_graphql) do
  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def lookup_key(key, options, context)
    confine_key = options['confine_to_key']
    raise ArgumentError, '[hiera-graphql] confine_to_key must be a string' unless confine_key.is_a?(String)

    graphql_query_opts = options['graphql_query_opts_lookup_key']
    raise ArgumentError, '[hiera-graphql] graphql_query_opts_lookup_key must be a string' unless graphql_query_opts.is_a?(String)

    unless confine_key == key
      context.explain { "[hiera-graphql] Skipping hiera_graphql backend because key '#{key}' does not match confine_to_key" }
      context.not_found
    end

    opts = call_function('lookup', graphql_query_opts)
    result = call_function('graphql::graphql_query', opts)

    return result if result
    context.not_found
  end
end
