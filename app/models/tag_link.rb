class TagLink < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :workflow, :inverse_of => :tag_links

  validates :tag_name, :uniqueness => { :scope => [:app_name, :object_type, :tenant_id] }
end
