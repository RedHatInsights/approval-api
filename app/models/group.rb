class Group < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :name, :presence => true

  has_many :approvergroups, :dependent => :destroy
  has_many :approvers, -> { order(:id => :asc) }, :through => :approvergroups
  has_many :stages, -> { order(:id => :asc) },    :dependent => :destroy, :inverse_of => :group
  has_many :workflowgroups, :dependent => :destroy
  has_many :workflows, -> { order(:id => :asc) }, :through => :workflowgroups, :inverse_of => :group

  def join_approvers(ids)
    candidates = Approver.find(ids)
    self.approvers |= candidates
  end

  def withdraw_approvers(ids)
    candidates = Approver.find(ids)
    self.approvers = self.approvers.reject { |a| candidates.include?(a) }
  end
end
