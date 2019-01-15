class Workflowgroup < ApplicationRecord
  belongs_to :workflow
  belongs_to :group
end
