require 'kie_client'
module Kie
  class Service
    def self.call(klass, options)
      setup(options)
      yield init(klass)
    rescue KieClient::ApiError => err
      Rails.logger.error("KieClient::ApiError #{err.message} ")
      raise Exceptions::KieError, "KieClient::ApiError: #{err.message}"
    end

    private_class_method def self.setup(options)
      KieClient.configure do |config|
        config.host      = options['host'] || 'localhost'
        config.scheme    = options['host'].try(:scheme) || 'http'
        config.username  = options['username']
        config.password  = options['password']
        config.base_path = options['base_path'] if options['base_path']
      end
    end

    private_class_method def self.init(klass)
      klass.new.tap do |api|
        api.api_client.default_headers['Authorization'] = KieClient.configure.basic_auth_token
      end
    end
  end
end
