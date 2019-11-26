class RequestContext < ApplicationRecord
  before_create :set_context

  private

  def set_context
    self.context = Insights::API::Common::Request.current.to_h
  end
end
