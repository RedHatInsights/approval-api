class Group < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :name, :presence => true

  has_many :usergroups, :dependent => :destroy
  has_many :users, -> { order(:id => :asc) }, :through => :usergroups
  has_many :stages, -> { order(:id => :asc) }, :dependent => :destroy, :inverse_of => :group
  has_many :workflowgroups, :dependent => :destroy
  has_many :workflows, -> { order(:id => :asc) }, :through => :workflowgroups, :inverse_of => :group

  def join_users(ids)
    candidates = User.find(ids)
    self.users |= candidates
  end

  def withdraw_users(ids)
    candidates = User.find(ids)
    self.users = self.users.reject { |a| candidates.include?(a) }
  end
end
