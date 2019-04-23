class Workflow < ApplicationRecord
  acts_as_tenant(:tenant, :has_global_records => true)

  belongs_to :template
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow

  validates :name, :presence => true
  validate :unique_with_same_or_no_tenant

  before_destroy :not_to_delete_default

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

  def unique_with_same_or_no_tenant
    if name_changed? && Workflow.exists?(:name => name)
      errors.add(:name, "has already been taken")
    end
  end

  def external_processing?
    template.process_setting.present?
  end

  def external_signal?
    template.signal_setting.present?
  end

  private

  def not_to_delete_default
    throw :abort if self.class.send(:default_workflow_query) == {:name => name, :template => template}
  end
end
