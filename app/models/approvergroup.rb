class Approvergroup < ApplicationRecord
  belongs_to :approver
  belongs_to :group
end
