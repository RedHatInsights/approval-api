class WorkflowPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission_check('read', scope) ? scope.all : (raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}")
    end
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
    permission_check('delete')
  end

  def link?
    permission_check('link')
  end

  def unlink?
    permission_check('unlink')
  end
end
