module ApprovalStates
  PENDING_STATE   = 'pending'.freeze
  SKIPPED_STATE   = 'skipped'.freeze
  STARTED_STATE   = 'started'.freeze
  NOTIFIED_STATE  = 'notified'.freeze
  COMPLETED_STATE = 'completed'.freeze
  CANCELED_STATE  = 'canceled'.freeze
  STATES = [PENDING_STATE, SKIPPED_STATE, STARTED_STATE, NOTIFIED_STATE, COMPLETED_STATE, CANCELED_STATE].freeze
  FINISHED_STATES = [SKIPPED_STATE, COMPLETED_STATE, CANCELED_STATE].freeze
end
