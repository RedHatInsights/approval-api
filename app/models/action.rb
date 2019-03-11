class Action < ApplicationRecord
  acts_as_tenant(:tenant)

  NOTIFY_OPERATION  = 'notify'.freeze
  SKIP_OPERATION    = 'skip'.freeze
  MEMO_OPERATION    = 'memo'.freeze
  APPROVE_OPERATION = 'approve'.freeze
  DENY_OPERATION    = 'deny'.freeze
  OPERATIONS = [NOTIFY_OPERATION, SKIP_OPERATION, MEMO_OPERATION, APPROVE_OPERATION, DENY_OPERATION].freeze

  DATE_ATTRIBUTES     = %w[created_at updated_at].freeze
  NON_DATE_ATTRIBUTES = %w[processed_by operation comments stage_id].freeze

  validates :operation,    :inclusion => { :in => OPERATIONS }
  validates :processed_by, :presence  => true
  belongs_to :stage, :inverse_of => :actions

  def as_json(_options = {})
    attributes.slice(*NON_DATE_ATTRIBUTES).tap do |hash|
      DATE_ATTRIBUTES.each do |attr|
        hash[attr] = send(attr.to_sym).iso8601 if send(attr.to_sym)
      end
    end.merge(:id => id.to_s)
  end
end
