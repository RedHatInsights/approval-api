class WorkflowPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return graphql_id_query if graphql_query_by_id?
      raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}" unless permission_check('read', scope)

      graphql_query? ? graphql_collection_query : scope.all
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
