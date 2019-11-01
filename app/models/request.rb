class Request < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions
  include OwnerField

  acts_as_tenant(:tenant)
  acts_as_tree

  belongs_to :request_context, :optional => false
  belongs_to :workflow
  has_many :stages, -> { order(:id => :asc) }, :inverse_of => :request, :dependent => :destroy

  validates :name,     :presence  => true
  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  scope :decision,       ->(decision)       { where(:decision => decision) }
  scope :state,          ->(state)          { where(:state => state) }
  scope :owner,          ->(owner)          { where(:owner => owner) }
  scope :requester_name, ->(requester_name) { where(:requester_name => requester_name) }
  default_scope { order(:created_at => :desc) }

  delegate :content, :to => :request_context
  delegate :context, :to => :request_context

  after_initialize :set_defaults

  def as_json(options = {})
    super.merge(:total_stages => total_stages, :active_stage => active_stage_number)
  end

  def current_stage
    stages.find_by(:state => [Stage::NOTIFIED_STATE, Stage::PENDING_STATE])
  end

  def number_of_children
    children.size
  end

  def number_of_finished_children
    children.count { |child| Request::FINISHED_STATES.include?(child.state) }
  end

  def create_child
    self.class.create!(:name => name, :description => description, :owner => owner, :requester_name => requester_name, :parent_id => id, :request_context_id => request_context_id)
  end

  private

  def set_defaults
    return unless new_record?

    self.state    = Request::PENDING_STATE
    self.decision = Request::UNDECIDED_STATUS
  end

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
end
