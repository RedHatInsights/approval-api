class Request < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions
  include OwnerField

  acts_as_tenant(:tenant)

  belongs_to :request_context, :optional => false
  belongs_to :workflow
  has_many :actions, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :request
  has_many :random_access_keys, :dependent => :destroy, :inverse_of => :request

  belongs_to :parent,   :foreign_key => :parent_id, :class_name => 'Request', :inverse_of => :children
  has_many   :children, :foreign_key => :parent_id, :class_name => 'Request', :inverse_of => :parent, :dependent => :destroy

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
    return if number_of_children.zero?

    update(:number_of_finished_children => children.count(&:finished?))
  end

  def create_child
    self.class.create!(:name => name, :description => description, :owner => owner, :requester_name => requester_name, :parent_id => id, :request_context_id => request_context_id).tap do
      invalidate_number_of_children
    end
  end

  def root
    root? ? self : parent
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    number_of_children.zero?
  end

  def child?
    parent_id.present?
  end

  def parent?
    number_of_children.nonzero?
  end

  def group
    @group ||= Group.find(group_ref)
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  private

  def set_defaults
    return unless new_record?

    self.state    = Request::PENDING_STATE
    self.decision = Request::UNDECIDED_STATUS

    self.number_of_children = 0
    self.number_of_finished_children = 0
  end
end
