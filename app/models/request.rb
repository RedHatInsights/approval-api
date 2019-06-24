class Request < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  belongs_to :workflow
  has_many :stages, -> { order(:id => :asc) }, :inverse_of => :request, :dependent => :destroy

  validates :name,      :presence => true
  validates :content,   :presence => true

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  scope :decision,  ->(decision)  { where(:decision => decision) }
  scope :state,     ->(state)     { where(:state => state) }
  scope :requester, ->(requester) { where(:requester => requester) }
  default_scope { order(:created_at => :desc) }

  before_create :set_context

  def as_json(options = {})
    super.merge(:total_stages => total_stages, :active_stage => active_stage_number)
  end

  def current_stage
    stages.find_by(:state => [Stage::NOTIFIED_STATE, Stage::PENDING_STATE])
  end

  private

  def total_stages
    stages.size
  end

  def active_stage_number
    return 0 if total_stages.zero?

    # return 1-based active stage
    active_stage = stages.find_index { |st| st.state == Stage::NOTIFIED_STATE || st.state == Stage::PENDING_STATE }
    if active_stage.nil?
      # no stage in active, must have completed
      stages.size
    else
      active_stage + 1
    end
  end

  def set_context
    self.context = ManageIQ::API::Common::Request.current.to_h
  end
end
