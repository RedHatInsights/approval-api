class RequestListByApproverService
  attr_accessor :username

  def initialize(username)
    self.username = username
  end

  def list
    group_refs = Group.all(username).map(&:uuid)

    workflows = Workflow.all.select do |flow|
      (flow.group_refs & group_refs).any?
    end

    Request.includes(:stages).where(:workflow_id => workflows.pluck(:id))
  end
end
