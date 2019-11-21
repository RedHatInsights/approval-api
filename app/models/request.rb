class Request < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions
  include OwnerField

  acts_as_tenant(:tenant)
  acts_as_tree

  belongs_to :request_context, :optional => false
  belongs_to :workflow
  has_many :actions, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :request

  validates :name,     :presence  => true
  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  scope :decision,       ->(decision)       { where(:decision => decision) }
  scope :state,          ->(state)          { where(:state => state) }
  scope :owner,          ->(owner)          { where(:owner => owner) }
  scope :requester_name, ->(requester_name) { where(:requester_name => requester_name) }
  scope :group_ref,      ->(group_ref)      { where(:group_ref => group_ref) }
  default_scope { order(:created_at => :desc) }

  delegate :content, :to => :request_context
  delegate :context, :to => :request_context

  after_initialize :set_defaults

  def invalidate_number_of_children
    update(:number_of_children => children.size)
  end

  def invalidate_number_of_finished_children
    update(:number_of_finished_children => children.count { |child| Request::FINISHED_STATES.include?(child.state) })
  end

  def create_child
    self.class.create!(:name => name, :description => description, :owner => owner, :requester_name => requester_name, :parent_id => id, :request_context_id => request_context_id).tap do
      invalidate_number_of_children
    end
  end

  def group
    @group ||= Group.find(group_ref)
  end

  private

  def set_defaults
    return unless new_record?

    self.state    = Request::PENDING_STATE
    self.decision = Request::UNDECIDED_STATUS
  end
end
