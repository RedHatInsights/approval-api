class GroupOperationService
  attr_accessor :group

  JOIN     = "join_approvers".freeze
  WITHDRAW = "withdraw_approvers".freeze

  GROUP_OPERATIONS = [JOIN, WITHDRAW].freeze

  def initialize(group_id)
    self.group = Group.find(group_id)
  end

  def operate(operation, params)
    raise StandardError, "Invalid group operation: #{operation}" unless GROUP_OPERATIONS.include?(operation)
    raise StandardError, "Invalid group operation params: #{params}" unless params[:approver_ids]

    group.send(operation, params[:approver_ids])
  end
end
