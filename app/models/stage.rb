class Stage < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  has_many :actions, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :stage

  belongs_to :request, :inverse_of => :stages

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  DATE_ATTRIBUTES     = %w(created_at updated_at)
  NON_DATE_ATTRIBUTES = %w(state decision reason request_id group_ref)

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
    attributes.slice(*NON_DATE_ATTRIBUTES).tap do |hash|
      DATE_ATTRIBUTES.each do |attr|
        hash[attr] = self.send(attr.to_sym).iso8601 if self.send(attr.to_sym)
      end
    end.merge(:id => id.to_s)
  end
end
