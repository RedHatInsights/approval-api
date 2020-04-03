module Metadata
  extend ActiveSupport::Concern

  included do
    attribute :metadata, ActiveRecord::Type::Json.new

    def metadata
      { :user_capabilities => user_capabilities }
    end

    def user_capabilities
      user_context.nil? ? { } : policy_name.new(user_context, self).user_capabilities
    end
  end
end
