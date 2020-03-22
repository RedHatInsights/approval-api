class RequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all unless Insights::API::Common::RBAC::Access.enabled?
      model = scope.class == Class ? scope : scope.model

      return scope.where(:parent_id => nil) if admin?(model)

      ids = approver?(model) ? approver_id_list(model.table_name) : owner_id_list(model.table_name)
      scope.where(:id => ids)
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
