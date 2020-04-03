require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  include Pundit

  self.abstract_class = true

  def metadata
    user_context.nil? ? { :user_capabilities => {} } : {:user_capabilities => policy_name.new(user_context, self).user_capabilities}
  end

  def user_context
    Thread.current[:user]
  end

  def policy_name
    PolicyFinder.new(self).policy
  end
end
