class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return graphql_id_query if graphql_query_by_id?
      raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}" unless permission_check('read', scope)

      graphql_query? ? graphql_collection_query : scope.all
    end
  end

  def show?
    permission_check('read')
  end
end
