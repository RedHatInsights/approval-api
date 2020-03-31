class RequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all unless user.rbac_enabled?

      if scope.class == Class
        scopes = access.scopes(scope.table_name, 'read')
        if scopes.include?("admin")
          scope.where(:parent_id => nil)
        elsif scopes.include?("group")
          scope.where(:id => approver_id_list(scope.table_name))
        elsif scopes.include?("user")
          scope.where(:parent_id => nil, :id => owner_id_list(scope.table_name))
        else
          Rails.logger.error("Error in request resolve: scope does not include admin, group, or user. List of scopes: #{scopes}")
          scope.none
        end
      else
        scope
      end
    end
  end

  def create?
    klass = record.class == Request ? record.class : record
    permission_check('create', klass)
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
    permission_check('read', record)
  end
end
