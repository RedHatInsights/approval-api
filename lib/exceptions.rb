module Exceptions
  class ApprovalError < StandardError; end
  class NoTenantError < StandardError; end
  class NotAuthorizedError < StandardError; end
  class RBACError < StandardError; end
  class KieError < StandardError; end
  class InvalidStateTransitionError < StandardError; end
  class UserError < StandardError; end
  class NegativeSequence < StandardError; end
  class TaggingError < StandardError; end
  class NetworkError < StandardError; end
  class TimedOutError < StandardError; end
end
