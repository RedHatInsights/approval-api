class DeleteAlwaysApproveFromWorkflows < ActiveRecord::Migration[5.2]
  def up
    always_approve = Workflow.find_by(:name => 'Always approve')
    return unless always_approve

    Request.where(:workflow => always_approve).update_all(:workflow_id => nil)
    always_approve.delete
  end

  def down
    Workflow.create(:name => 'Always approve', :description => 'Always auto approve by system. No approvers are assigned.')
  end
end
