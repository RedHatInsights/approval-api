class Request < ApplicationRecord
  include Filterable
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  belongs_to :workflow
  has_many :stages, -> { order(:id => :asc) }, :inverse_of => :request, :dependent => :destroy

  validates :requester, :presence => true
  validates :name,      :presence => true
  validates :content,   :presence => true

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  scope :decision,  ->(decision)  { where(:decision => decision) }
  scope :state,     ->(state)     { where(:state => state) }
  scope :requester, ->(requester) { where(:requester => requester) }

  DATE_ATTRIBUTES     = %w(created_at updated_at)
  NON_DATE_ATTRIBUTES = %w(requester name description state decision reason content workflow_id)

  def as_json(_options = {})
    attributes.slice(*NON_DATE_ATTRIBUTES).tap do |hash|
      DATE_ATTRIBUTES.each do |attr|
        hash[attr] = self.send(attr.to_sym).iso8601 if self.send(attr.to_sym)
      end
    end.merge(:id => id.to_s)
  end
end
