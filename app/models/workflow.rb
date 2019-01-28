class Workflow < ApplicationRecord
  acts_as_tenant(:tenant, :has_global_records => true)

  belongs_to :template
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow
  has_many :workflowgroups, :dependent => :destroy
  has_many :groups, -> { order(:id => :asc) }, :through => :workflowgroups

  validates :name, :presence => :name

  def self.seed
    workflow = find_or_create_by!(default_workflow_query)
    workflow.update_attributes!(
      :description => 'Always auto approve by system. No approvers are assigned.'
    )
  end

  def self.default_workflow
    @default_workflow ||= find_by(default_workflow_query)
  end

  def self.default_workflow_query
    { :name => 'Always approve', :template => nil }
  end
  private_class_method :default_workflow_query
end
