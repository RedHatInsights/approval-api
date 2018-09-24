class Template < ApplicationRecord
  has_many :workflows, dependent: :destroy

  validates_presence_of :title, :description, :created_by
end
