# Define custom exception mappings here to make sure they are loaded last
ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  "ActiveRecord::RecordNotSaved"            => :bad_request,
  "ActiveRecord::RecordInvalid"             => :bad_request,
  "ActionController::ParameterMissing"      => :bad_request,
  "Exceptions::InvalidStateTransitionError" => :bad_request,
  "Exceptions::NotAuthorizedError"          => :forbidden,
  "Exceptions::RBACError"                   => :service_unavailable,
  "Exceptions::KieError"                    => :service_unavailable
)
