class WorkflowUpdateService
  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def update(options)
    options[:access_control_entries] =
      (options[:group_refs] || []).collect do |uuid|
        AccessControlEntry.new(:group_uuid => uuid, :permission => 'approve')
      end

    workflow.update!(options)
  end
end
