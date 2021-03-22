if ClowderCommonRuby::Config.clowder_enabled?
  config = ClowderCommonRuby::Config.load

  # ManageIQ Message Client depends on these variables
  ENV["QUEUE_HOST"] = config.kafka.brokers.first.hostname
  ENV["QUEUE_PORT"] = config.kafka.brokers.first.port.to_s
  ENV["QUEUE_NAME"] = config.kafka.topics.first.name

  # ManageIQ Logger depends on these variables
  ENV['CW_AWS_ACCESS_KEY_ID'] = config.logging.cloudwatch.accessKeyId
  ENV['CW_AWS_SECRET_ACCESS_KEY'] = config.logging.cloudwatch.secretAccessKey
  ENV['CW_AWS_REGION'] = config.logging.cloudwatch.region # not required
  ENV['CLOUD_WATCH_LOG_GROUP'] = config.logging.cloudwatch.logGroup

  config.endpoints.each do |endpoint|
    if endpoint.app == 'rbac' && endpoint.name == 'service'
      ENV['RBAC_URL'] = "http://#{endpoint.hostname}:#{endpoint.port}"
    end
  end
end
