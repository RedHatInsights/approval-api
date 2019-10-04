class Stage < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  has_many :actions, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :stage

  belongs_to :request, :inverse_of => :stages

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  def notified_at
    actions.where(:operation => Action::NOTIFY_OPERATION).pluck(:created_at).first
  end

  def name
    group.try(:name)
  end

  def attributes
    super.merge('name' => name, 'notified_at' => notified_at)
  end

  # starts from 1
  def index_of_request
    request.stages.find_index { |stage| stage.id == id } + 1
  end

  def group
    @group ||= Group.find(group_ref)
  end
end
