class RequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all unless Insights::API::Common::RBAC::Access.enabled?

      # parent request index
      if scope.class == Class
        return scope.where(:parent_id => nil) if admin?(scope)
        return scope.where(:id => approver_id_list(scope.table_name)) if approver?(scope)

        scope.where(:parent_id => nil, :id => owner_id_list(scope.table_name))
      # child request index
      else
        scope
      end
    end
  end

  def create?
    permission_check('create')
  end

  def show?
    resource_check('read')
  end

  # only for child requests
  def index?
    resource_check('read', record.id, record.class)
  end
 
  # define for graphql
  def query?
    permission_check('read')
  end
end
