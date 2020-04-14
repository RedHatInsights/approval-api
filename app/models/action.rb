class Action < ApplicationRecord
  acts_as_tenant(:tenant)

  NOTIFY_OPERATION  = 'notify'.freeze
  START_OPERATION   = 'start'.freeze
  SKIP_OPERATION    = 'skip'.freeze
  MEMO_OPERATION    = 'memo'.freeze
  APPROVE_OPERATION = 'approve'.freeze
  DENY_OPERATION    = 'deny'.freeze
  CANCEL_OPERATION  = 'cancel'.freeze
  ERROR_OPERATION   = 'error'.freeze
  OPERATIONS = [START_OPERATION, NOTIFY_OPERATION, SKIP_OPERATION, MEMO_OPERATION, APPROVE_OPERATION, DENY_OPERATION, CANCEL_OPERATION, ERROR_OPERATION].freeze

  ADMIN_OPERATIONS     = [MEMO_OPERATION, APPROVE_OPERATION, DENY_OPERATION, CANCEL_OPERATION].freeze
  APPROVER_OPERATIONS  = [MEMO_OPERATION, APPROVE_OPERATION, DENY_OPERATION].freeze
  REQUESTER_OPERATIONS = [CANCEL_OPERATION].freeze

  validates :operation, :inclusion => { :in => OPERATIONS }
  validates :processed_by, :presence  => true
  belongs_to :request, :inverse_of => :actions
end
