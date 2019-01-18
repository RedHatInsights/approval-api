class Template < ApplicationRecord
  acts_as_tenant(:tenant, :has_global_records => true)

  has_many :workflows, -> { order(:id => :asc) }, :inverse_of => :template

  validates :title, :presence => :title

  def self.seed
    template = find_or_create_by!(:title => 'Basic')
    template.update_attributes(
      :description => 'A basic approval workflow that supports multi-level approver groups through email notification'
    )
  end
end
