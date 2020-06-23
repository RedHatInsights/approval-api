class WorkflowPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def create?
    klass = record.class == Workflow ? record.class : record
    permission_check('create', klass)
  end

  def show?
    permission_check('read')
  end

  def update?
    permission_check('update')
  end

  def destroy?
    permission_check('delete') ? record.deletable? : false
  end

  def link?
    permission_check('link')
  end

  def unlink?
    permission_check('unlink')
  end
end
