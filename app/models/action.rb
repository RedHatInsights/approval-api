class Action < ApplicationRecord
  acts_as_tenant(:tenant)

  NOTIFY_OPERATION  = 'notify'.freeze
  SKIP_OPERATION    = 'skip'.freeze
  MEMO_OPERATION    = 'memo'.freeze
  APPROVE_OPERATION = 'approve'.freeze
  DENY_OPERATION    = 'deny'.freeze
  OPERATIONS = [NOTIFY_OPERATION, SKIP_OPERATION, MEMO_OPERATION, APPROVE_OPERATION, DENY_OPERATION].freeze

  validates :operation, :inclusion => { :in => OPERATIONS }
  validates :processed_by, :presence  => true
  belongs_to :stage, :inverse_of => :actions
end
