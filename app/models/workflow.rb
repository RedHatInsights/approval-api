class Workflow < ApplicationRecord
  include Metadata
  acts_as_tenant(:tenant)

  acts_as_list :scope => [:tenant_id], :column => 'sequence'
  default_scope { order(:sequence => :asc) }

  belongs_to :template
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow
  has_many :access_control_entries, :as => :aceable, :dependent => :destroy, :inverse_of => :aceable

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}

  def external_processing?
    template&.process_setting.present?
  end

  def external_signal?
    template&.signal_setting.present?
  end
end
