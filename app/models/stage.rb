class Stage < ApplicationRecord
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  has_many :actions, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :stage

  belongs_to :group, :inverse_of => :stages
  belongs_to :request, :inverse_of => :stages

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }
end
