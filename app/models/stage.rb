class Stage < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions
  include Convertable

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

  def group
    @group ||= Group.find(group_ref)
  end

  def as_json(_options = {})
    convert_date_id(attributes)
  end
end
