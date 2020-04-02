require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  attribute :metadata, ActiveRecord::Type::Json.new

  def metadata
    { :user_capabilities => {} }
  end

  def user_context
    Thread.current[:user]
  end
end
