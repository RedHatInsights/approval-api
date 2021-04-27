if ClowderCommonRuby::Config.clowder_enabled?
  config = ClowderCommonRuby::Config.load

  # ManageIQ Message Client depends on these variables
  ENV["QUEUE_HOST"] = config.kafka.brokers.first.hostname
  ENV["QUEUE_PORT"] = config.kafka.brokers.first.port.to_s
  ENV["QUEUE_NAME"] = config.kafka.topics.first.name

  config.endpoints.each do |endpoint|
    if endpoint.app == 'rbac' && endpoint.name == 'service'
      ENV['RBAC_URL'] = "http://#{endpoint.hostname}:#{endpoint.port}"
    end
  end
end
