module Metadata
  extend ActiveSupport::Concern

  included do
    attribute :metadata, ActiveRecord::Type::Json.new

    def metadata
      { :user_capabilities => user_capabilities }
    end

    def user_capabilities
      user_context.nil? ? { } : policy_class.new(user_context, self).user_capabilities
    end

    def policy_class
      "#{self.class}Policy".constantize
    end
  end
end
