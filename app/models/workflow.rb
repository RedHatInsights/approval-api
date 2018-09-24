class Workflow < ApplicationRecord
  belongs_to :template
  has_many :requests, dependent: :destroy

  validates_presence_of :name

  serialize :groups, Array
end
