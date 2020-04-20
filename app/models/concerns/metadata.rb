module Metadata
  extend ActiveSupport::Concern

  included do
    attribute :metadata, ActiveRecord::Type::Json.new
  end

  class_methods do
    def policy_class
      @policy_class ||= "#{self}Policy".constantize
    end
  end

  def metadata
    { :user_capabilities => user_capabilities }
  end

  private

  def user_capabilities
    user_context.nil? ? { } : self.class.policy_class.new(user_context, self).user_capabilities
  end
end
