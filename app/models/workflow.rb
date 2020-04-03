class Workflow < ApplicationRecord
  acts_as_tenant(:tenant)

  attribute :metadata, ActiveRecord::Type::Json.new
  acts_as_list :scope => [:tenant_id], :column => 'sequence'
  default_scope { order(:sequence => :asc) }

  belongs_to :template
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow
  has_many :access_control_entries, :as => :aceable, :dependent => :destroy, :inverse_of => :aceable

  validates :name, :presence => true
  validate :unique_with_same_tenant

  def unique_with_same_tenant
    if name_changed? && Workflow.exists?(:name => name)
      errors.add(:name, "has already been taken")
    end
  end

  def external_processing?
    template&.process_setting.present?
  end

  def external_signal?
    template&.signal_setting.present?
  end
end
