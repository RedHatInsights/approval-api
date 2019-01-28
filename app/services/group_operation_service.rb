class GroupOperationService
  attr_accessor :group

  JOIN     = "join_users".freeze
  WITHDRAW = "withdraw_users".freeze

  GROUP_OPERATIONS = [JOIN, WITHDRAW].freeze

  def initialize(group_id)
    self.group = Group.find(group_id)
  end

  def operate(operation, params)
    raise StandardError, "Invalid group operation: #{operation}" unless GROUP_OPERATIONS.include?(operation)
    raise StandardError, "Invalid group operation params: #{params}" unless params[:user_ids]

    group.send(operation, params[:user_ids])
  end
end
