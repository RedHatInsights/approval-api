require 'kie_client'
module Kie
  class Service
    def self.call(klass)
      setup
      yield init(klass)
    rescue KieClient::ApiError => err
      Rails.logger.error("KieClient::ApiError #{err.message} ")
      raise Exceptions::KieError, err.message
    end

    private_class_method def self.setup
      KieClient.configure do |config|
        config.host     = ENV['KIESERVER_URL'] || 'localhost'
        config.scheme   = URI.parse(ENV['KIESERVER_URL']).try(:scheme) || 'http'
        config.username = ENV['KIESERVER_USERNAME'] || raise("Empty ENV variable: KIESERVER_USERNAME")
        config.password = ENV['KIESERVER_PASSWORD'] || raise("Empty ENV variable: KIESERVER_PASSWORD")
      end
    end

    private_class_method def self.init(klass)
      klass.new.tap do |api|
        api.api_client.default_headers['Authorization'] = KieClient.configure.basic_auth_token
      end
    end
  end
end
