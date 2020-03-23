class ChangeGroupRefsFormat < ActiveRecord::Migration[5.2]
  def up
    Workflow.find_each do |wf|
      wf.group_refs = wf.group_refs.collect do |uuid|
        {'uuid' => uuid, 'name' => 'Unknown'}
      end
      wf.save!
    end
  end

  def down
    Workflow.find_each do |wf|
      wf.group_refs = wf.group_refs.collect do |pair|
        pair['uuid']
      end
      wf.save!
    end
  end
end
