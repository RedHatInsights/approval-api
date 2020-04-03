require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  include Pundit

  self.abstract_class = true

  def user_context
    UserContext.current_user_context
  end
end
