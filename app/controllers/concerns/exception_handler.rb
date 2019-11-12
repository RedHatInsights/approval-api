module ExceptionHandler
  # provides the more graceful `included` method
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({ :message => e.message }, :not_found)
    end

    rescue_from ManageIQ::API::Common::EntitlementError do |e|
      json_response({ :message => e.message }, :forbidden)
    end

    rescue_from Exceptions::UserError, Exceptions::ApprovalError do |e|
      json_response({ :message => e.message }, :bad_request)
    end
  end
end
