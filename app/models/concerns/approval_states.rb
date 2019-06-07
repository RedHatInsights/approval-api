module ApprovalStates
  PENDING_STATE  = 'pending'.freeze
  SKIPPED_STATE  = 'skipped'.freeze
  NOTIFIED_STATE = 'notified'.freeze
  FINISHED_STATE = 'finished'.freeze
  CANCELED_STATE = 'canceled'.freeze
  STATES = [PENDING_STATE, SKIPPED_STATE, NOTIFIED_STATE, FINISHED_STATE, CANCELED_STATE].freeze
end
