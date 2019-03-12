class Request < ApplicationRecord
  include Filterable
  include Convertable
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

  def as_json(_options = {})
    convert_date_id(attributes)
  end
end
